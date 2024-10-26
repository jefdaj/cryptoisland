---
title: Simple Cardano "batching bots" for concurrent DEX protocols
tags: blockchain, cardano, plutus, concurrency, utxo, brainstorm, dex
updated: 2021-09-11
reminder: many-arm-robot.png
...

Everyone seems so interested in [Cardano][cardano]'s [concurrency problem][problem]
that I decided it's worth posting my own half-baked solution.
This is mainly based on (and almost identical to?) [Chris from Mirqur's idea][chris].
It sounds like others are thinking along similar lines as well.

*Update: [MELD has a simpler solution][meld] that removes the need for an
auction by requiring a predefined set of UTXOs to be used as user inputs. That
looks better for most use cases. I could see it having an issue with
auction sniping though.*

*Update: only one bid can reference each original trade UTXO; subsequent bids
just reference the previous state*

# A (relatively) simple batching protocol

The basic idea is to have a three-phase protocol for updating the [DEX][dex] state:

1. First, everyone who wants to interact with the DEX posts a transaction that
	 announces the trade they intend to make. It doesn't actually consume the
	 current DEX state though. They would just send their tokens to a
	 DEX-controlled script address that acts like a queue with an attached datum
	 specifying the trade parameters they agree to. A large number of them could
	 be submitted at once during one or several slots.

2. Next, an "auction" where anyone can run a bot that gathers up all the posted
	 trades and executes them at once according to the DEX logic. They would be
	 paid a small fee for doing it, and have to post collateral to be slashed if
	 they leave any valid trades out. Each "bid" has to include all previous
	 valid transactions plus at least one new one.

3. After waiting a few slots for any more state transition bids to appear, the
	 final step is to apply the highest-bidding transition to the main DEX UTXO,
	 reward the winning bidder, and slash any other bidders' collateral. Anyone
	 could do this step as well but the winning bot is the one with the most
	 incentive.

Here's an example workflow. Rectangles are transactions and ovals are UTXOs.
Color indicates who controls each thing: blue for a user, green for a bot,
orange for the DEX contract.

~~~{ lang="dot-as-svg" }
digraph protocol {
  rankdir=TB
  bgcolor=transparent
  node [style=filled, fillcolor=white]
  edge [color=grey]

  // nodes outside the protocol
  Wallet1 [fillcolor="#66ddff"]
  Wallet2 [fillcolor="#66ddff"]
  Wallet3 [fillcolor="#66ddff"]
  BotWallet1 [fillcolor=lightgreen]
  BotWallet2 [fillcolor=lightgreen]
  Wallet1p [label="Wallet1", fillcolor="#66ddff"]
  Wallet2p [label="Wallet2", fillcolor="#66ddff"]
  Wallet3p [label="Wallet3", fillcolor="#66ddff"]
  BotWallet1p [label="BotWallet1", fillcolor=lightgreen]
  BotWallet2p [label="BotWallet2", fillcolor=lightgreen]
  State1 [fillcolor="#F6B657"]
  State4 [fillcolor="#F6B657"]

  node [shape=rect, fillcolor="#66ddff"]
  UserWallet3 [label="User3 posts trade"]
  UserWallet2 [label="User2 posts trade"]
  UserWallet1 [label="User1 posts trade"]

  node [shape=oval, fillcolor=white]
  Wallet3 -> UserWallet3
  Wallet1 -> UserWallet1
  Wallet2 -> UserWallet2

  subgraph cluster_phase1 {
    bgcolor="#fbeee0"
    label="Phase 1: announce trades in parallel"
    node [shape=oval]
    Trade1 [fillcolor="#F6B657"]
    Trade2 [fillcolor="#F6B657"]
    Trade3 [fillcolor="#F6B657"]

    UserWallet3 -> Trade3
    UserWallet1 -> Trade1
    UserWallet2 -> Trade2
  }

  subgraph cluster_phase2 {
    bgcolor="#fbeee0"
    label="Phase 2: single-threaded batching auction"
    Batch1 [label="Bot1 bids 2 trades,\nposts collateral", shape=rect, fillcolor=lightgreen]
    Batch2 [label="Bot2 bids 3 trades,\nposts collateral", shape=rect, fillcolor=lightgreen]
    State2 [fillcolor="#F6B657"]
    State3 [fillcolor="#F6B657"]
  }

  subgraph cluster_phase3 {
    bgcolor="#fbeee0"
    label="Phase 3: finalize winning state transition"
    Finalize [shape=rect, fillcolor=lightgreen, label="Bot2 applies all 3 trades,\nslashes Bot1 for omitting Trade3,\nrewards itself,\ndistributes traded tokens"]
  }

  State2
  State3

  State1 -> Batch1 -> State2
  Trade1 -> Batch1
  Trade2 -> Batch1
  BotWallet1 -> Batch1

  BotWallet2 -> Batch2
  Trade3 -> Batch2

  State2 -> Batch2 -> State3

  State3 -> Finalize
  Finalize -> Wallet1p
  Finalize -> Wallet2p
  Finalize -> Wallet3p
  Finalize -> BotWallet1p
  Finalize -> BotWallet2p
  Finalize -> State4
}
~~~

Something like this should work for not only a DEX, but for any contract that
needs someone to post a state transition and be assured that they include all
the valid inputs. For example a concurrent auction contract could tip a
bot for calling its `close` endpoint and gathering all valid bids at the end of
the auction. (I imagine this would come up a lot in real auctions, since
everyone would wait to [snipe][snipe] at the end)

The simplest way I can think of bootstrapping a generalized bot economy would
be to have a `cardano-batch-bot-contrib` or similar repo where everyone posts
code for operating a bot on their protocol, and bot operators choose which ones
to include. Any [stake pool][pool] operator (SPO) who wants some extra revenue could
also operate a bot and customize it to run only the protocols they're
comfortable with.

# Potential objections

Q: Is this too complicated or too slow to operate at scale?

A: I don't think so. This protocol could probably be run on the main chain at
least as fast as an oracle could come to consensus on price changes. Trades
would be ordered by the slot they were submitted in, which is the same level of
resolution a trivial "single-threaded" DEX would be capable of. And inside a
[Hydra head][hydra] it could go orders of magnitude faster. Probably fast
enough that users wouldn't notice any delay at all! Finally, because cheating bots
will always be caught, there should normally only be one bid.

Q: Would this introduce [nondeterminism][nondeterminism] and [miner-extractable value (MEV)][mev]?

A: It depends whether the DEX protocol is deterministic. Batching bots would
probably end up being run by SPOs and the [slot leader][leader] would be able to include
their own batch transaction, but they would be unable to censor or re-order
transactions unless the DEX contract + batching protocol allows it.

Q: Would batching bot operators be legally responsible for operating an order
book, like [what happened to EtherDelta][etherdelta]?

A: I have no legal training whatsoever, but it seems to me that that should
also depend on whether the protocol is deterministic. If so, bot operators
don't have any decision-making power to abuse and therefore don't need to be
regulated. The only choice they would have is whether to participate in the
protocol at all or not. One could imagine situations where everyone might
refuse to process money from a hack for example, but I think that would be
better regulated at the DEX protocol level so everyone is clear on what counts
as a legal trade beforehand. The founders, devs, or token holders might be
responsible in that case.

# Next steps

Lots of things would still need to be worked out. For example:

* How long should each phase take?
* Should the phases be defined by number of slots, number of transactions, or
	some combination?
* Can phase 1 be done in parallel with the previous iteration of phase 2+3?
* What kind of rewards and slashing would be appropriate?

[cardano]: https://cardano.org
[chris]: https://www.youtube.com/watch?v=_wVpC7XWN1M
[etherdelta]: https://www.mme.ch/en/magazine/magazine-detail/url_magazine/etherdelta_regulierung_von_dezentralisierten_boersen/
[hydra]: https://iohk.io/en/blog/posts/2020/03/26/enter-the-hydra-scaling-distributed-ledgers-the-evidence-based-way/
[problem]: https://coindesk-news.com/2021/09/06/on-minswap-iohk-defuses-complaints-about-cardano-concurrency/
[snipe]: https://en.wikipedia.org/wiki/Auction_sniping
[dex]: https://en.wikipedia.org/wiki/Decentralized_exchange
[pool]: https://iohk.zendesk.com/hc/en-us/articles/900001951526-What-is-a-stake-pool-
[leader]: https://cardano-foundation.gitbook.io/stake-pool-course/lessons/introduction/about-cardano#slot-leader-election
[mev]: https://coinmarketcap.com/alexandria/glossary/miner-extractable-value-mev
[nondeterminism]: https://iohk.io/en/blog/posts/2021/09/06/no-surprises-transaction-validation-on-cardano/
[meld]: https://medium.com/meld-labs/concurrent-deterministic-batching-on-the-utxo-ledger-99040f809706
