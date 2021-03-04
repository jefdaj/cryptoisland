---
title: Why learn Plutus?
tags: plutus, haskell, smart-contracts, cardano, solidity, ethereum
...

Most smart contracts in use today are written in [Solidity][solidity] and run
on [Ethereum][ethereum]. [Plutus][plutus] is the native language of
[Cardano][cardano], a competing platform with a slower and more academic ethos.
They haven't even launched contracts on mainnet yet! So why bother learning this
arcane language?

Personally I think [their academic work so far][papers] is an amazing treasure
trove of breakthroughs unmatched by any other crypto project. They range across
topics like [environmental sustainability][pos], [scaling][hydra],
[governance][treasury], and [privacy][privacy], and they are building toward
something fundamentally better than anything in production today. As far as I
can tell, the main reason the market doesn't reflect that is because most
people haven't gotten around to reading the papers.

But even if that turns out to be a naive and biased opinion, learning
another programming style with different tradeoffs will still make you a better
Solidity developer. It's analagous to [why you should learn
Haskell][why-learn]. Also it *is* pretty similar to Haskell, and the functional
programming paradigm---immutable data structures, static analysis of types,
stateless functions guaranteed to work in parallel---seems especially well
suited to a blockchain context.

<!-- Assuming you're interested, see [the intro series][intro]. -->

[solidity]: https://docs.soliditylang.org/en/v0.5.3/solidity-by-example.html
[ethereum]: https://ethereum.org/en/
[plutus]: https://docs.cardano.org/projects/plutus/en/latest/
[cardano]: https://cardano.org/
[papers]: https://iohk.io/en/research/library/
[privacy]: https://iohk.io/en/research/library/papers/ouroboros-crypsinousprivacy-preserving-proof-of-stake/
[pos]: https://iohk.io/en/research/library/papers/ouroborosa-provably-secure-proof-of-stake-blockchain-protocol/
[hydra]: https://iohk.io/en/research/library/papers/hydrafast-isomorphic-state-channels/
[treasury]: https://iohk.io/en/research/library/papers/a-treasury-system-for-cryptocurrenciesenabling-better-collaborative-intelligence/
[why-learn]: https://dev.to/mpodlasin/5-practical-reasons-why-your-next-programming-language-to-learn-should-be-haskell-gc
[intro]: ../../04/plutus-intro/index.html
