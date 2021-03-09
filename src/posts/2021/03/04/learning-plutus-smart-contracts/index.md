---
title: Learning Plutus smart contracts
tags: plutus, cardano
toc: true
...

Welcome to a series of posts wherein I try to learn [smart contract][smart-contract]
development by teaching it. I'll aim to do at least a couple short sessions per
week, largely based on the [Plutus smart contracts][leanpub] ebook but also including
more recent documentation, YouTube channels, etc.

<!-- TODO what does he mean by it doesn't have data types? investigate that.
something about Scott representation? -->

# Why learn Plutus?

*Note: you can probably skip this if you already drink the functional
programming and/or Cardano Kool-Aid.*

Most smart contracts in use today are written in [Solidity][solidity] and run
on [Ethereum][ethereum]. [Plutus][plutus] is the native language of
[Cardano][cardano], a competing platform with a slower and more academic ethos.
Why bother learning something that's less popular and also arguably more
difficult?

Personally, I'm learning it because I think it will be better. I think [their
academic work so far][papers] is an amazing treasure trove of advances in
topics like [environmental sustainability][pos], [scaling][hydra],
[governance][treasury], and [privacy][privacy], and that the aggregate result
of all that research and development will be a fundamentally better protocol
that everyone wants to use.

But if I'm wrong about all that, learning another programming style with
different trade-offs will still make you a better Solidity developer. It's
analogous to [why you should learn Haskell][why-haskell]. Plutus is also
closely related to Haskell, and the functional programming paradigm---immutable
data structures, static analysis of types, stateless functions guaranteed to
work in parallel---seems well suited to a blockchain context.

I'm not saying you should *only* learn Plutus, or that you should necessarily
prioritize it over Solidity. I'll be doing some of both on this blog. But you
should at least learn enough of it to get a feel for the design patterns and
compare them.

# What to expect

Instead of trying to make a comprehensive guide, I'll just start expanding on
things I find confusing as a Haskell developer with no prior blockchain
experience, and then progress to mocking up naive implementations of some
interesting dApp ideas. Along the way there will probably be comparisons to
Marlowe, Solidity, and traditional programming. I hope it becomes a
useful supplement to the other available resources rather than a standalone
thing.

That said, [let me know](/about.html) if you want more about a particular
topic! Haskell, Solidity, blockchain, type theory, Nix, DAOs, whatever. And
correct me if I did something badly. It's all very interdisciplinary, and
everyone starts with a different subset of the skills. I might not know what I
don't know, or what you don't know.

Ready? Click the "plutus" tag at the top of the page to get started.

[cardano]: https://cardano.org/
[ethereum]: https://ethereum.org/en/
[haskell]: https://www.haskell.org/
[hydra]: https://iohk.io/en/research/library/papers/hydrafast-isomorphic-state-channels/
[leanpub]: https://leanpub.com/plutus-smart-contracts
[overview]: ../../05/plutus-overview/index.html
[papers]: https://iohk.io/en/research/library/
[plutus]: https://docs.cardano.org/projects/plutus/en/latest/
[pos]: https://iohk.io/en/research/library/papers/ouroborosa-provably-secure-proof-of-stake-blockchain-protocol/
[privacy]: https://iohk.io/en/research/library/papers/ouroboros-crypsinousprivacy-preserving-proof-of-stake/
[smart-contract]: https://www.investopedia.com/terms/s/smart-contracts.asp
[solidity]: https://docs.soliditylang.org/en/v0.5.3/solidity-by-example.html
[treasury]: https://iohk.io/en/research/library/papers/a-treasury-system-for-cryptocurrenciesenabling-better-collaborative-intelligence/
[why-haskell]: https://dev.to/mpodlasin/5-practical-reasons-why-your-next-programming-language-to-learn-should-be-haskell-gc
[why-learn]: ../why-learn-plutus/index.html
