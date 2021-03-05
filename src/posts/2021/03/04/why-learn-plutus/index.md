---
title: Why learn Plutus?
tags: plutus, cardano, solidity, ethereum, smart contracts
...

*Note: you can probably skip this if you already drink the functional
programming and/or Cardano Kool-Aid.*

Most smart contracts in use today are written in [Solidity][solidity] and run
on [Ethereum][ethereum]. [Plutus][plutus] is the native language of
[Cardano][cardano], a competing platform with a slower and more academic ethos.
Why bother learning something that's less popular and also arguably more
difficult?

Personally, I'm learning it because I think it will be better. I think [their
academic work so far][papers] is an amazing treasure trove of advancements on
topics like [environmental sustainability][pos], [scaling][hydra],
[governance][treasury], and [privacy][privacy], and that the aggregate result
of all that research and development will be a fundamentally better protocol
that everyone wants to use.

I could be wrong! But if nothing else, learning another programming style with
different trade-offs will still make you a better Solidity developer. It's
analogous to [why you should learn Haskell][why-haskell]. Plutus is also
closely related to Haskell, and the functional programming paradigm---immutable
data structures, static analysis of types, stateless functions guaranteed to
work in parallel---seems well suited to a blockchain context.

I'm not saying you should *only* learn Plutus, or that you should necessarily
prioritize it over Solidity. I'll be doing some of both on this blog. But you
should at least learn enough of it to get a feel for the design patterns and
compare them.

[solidity]: https://docs.soliditylang.org/en/v0.5.3/solidity-by-example.html
[ethereum]: https://ethereum.org/en/
[plutus]: https://docs.cardano.org/projects/plutus/en/latest/
[cardano]: https://cardano.org/
[papers]: https://iohk.io/en/research/library/
[privacy]: https://iohk.io/en/research/library/papers/ouroboros-crypsinousprivacy-preserving-proof-of-stake/
[pos]: https://iohk.io/en/research/library/papers/ouroborosa-provably-secure-proof-of-stake-blockchain-protocol/
[hydra]: https://iohk.io/en/research/library/papers/hydrafast-isomorphic-state-channels/
[treasury]: https://iohk.io/en/research/library/papers/a-treasury-system-for-cryptocurrenciesenabling-better-collaborative-intelligence/
[why-haskell]: https://dev.to/mpodlasin/5-practical-reasons-why-your-next-programming-language-to-learn-should-be-haskell-gc
