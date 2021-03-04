---
title: Why learn Plutus?
tags: plutus, haskell, smart-contracts, cardano, solidity, ethereum
...

Most smart contracts in use today are written in [Solidity][solidity] and run
on [Ethereum][ethereum]. [Plutus][plutus] is the native language of
[Cardano][cardano], a competing platform with a slower and more academic ethos.
They haven't even launched contracts on mainnet yet. So why bother learning the
less popular language?

Personally I think [their papers][papers] contain important breakthroughs in
[sustainability][pos], [scaling][hydra], [governance][treasury], and
[privacy][privacy] that point to a fundamentally better protocol, and the
market will eventually discover that.

But if not, learning another programming style with different tradeoffs will
still make you a better Solidity developer. It's analagous to [why you should
learn Haskell][why-learn]. Also it *is* Haskell, and the things it teaches
you---immutable data structures, static analysis with types, stateless
functions guaranteed to work in parallel---seem especially well suited to a
blockchain context.

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
