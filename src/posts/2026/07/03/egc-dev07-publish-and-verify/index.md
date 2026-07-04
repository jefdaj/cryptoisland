---
title: "ElectionGuard + Cardano Dev Update #7: Publish + Verify"
tags: electionguard, cardano, catalyst, fund13, elections, python, docker, dev-update
reminder: publish-and-verify.png
...

[aktypes]: https://github.com/jefdaj/electionguard-cardano/tree/trunk/milestone2/publish-and-verify/onchain/validators/election/types
[burn]: https://github.com/jefdaj/electionguard-cardano/blob/6dff12e55f7225cc4ab777e0676888256c702d90/milestone2/publish-and-verify/offchain/egc/nodes/funder.py#L294
[cid]: https://github.com/jefdaj/electionguard-cardano/blob/trunk/milestone2/publish-and-verify/offchain/egc/core/plutus/types/ipfs_cid.py
[code]:   https://github.com/jefdaj/electionguard-cardano/tree/trunk/milestone2/publish-and-verify
[design]: https://github.com/jefdaj/electionguard-cardano/tree/trunk/milestone2/design
[events]: https://github.com/jefdaj/electionguard-cardano/blob/6dff12e55f7225cc4ab777e0676888256c702d90/milestone2/publish-and-verify/offchain/egc/core/subscriber.py#L96
[f13]:    https://milestones.projectcatalyst.io/projects/1300090
[fixtures]: https://github.com/jefdaj/electionguard-cardano/blob/6dff12e55f7225cc4ab777e0676888256c702d90/milestone2/publish-and-verify/offchain/tests/conftest.py#L4
[flake]: https://github.com/jefdaj/electionguard-cardano/blob/trunk/milestone2/publish-and-verify/flake.nix
[logic]: https://github.com/jefdaj/electionguard-cardano/blob/6dff12e55f7225cc4ab777e0676888256c702d90/milestone2/publish-and-verify/offchain/egc/core/node.py#L105
[params]: https://github.com/jefdaj/electionguard-cardano/blob/6dff12e55f7225cc4ab777e0676888256c702d90/milestone2/publish-and-verify/offchain/egc/core/plutus/oneshot.py#L45
[pyc]: https://github.com/Python-Cardano/pycardano
[pytypes]: https://github.com/jefdaj/electionguard-cardano/tree/trunk/milestone2/publish-and-verify/offchain/egc/core/plutus/types
[recover]: https://github.com/jefdaj/electionguard-cardano/blob/6dff12e55f7225cc4ab777e0676888256c702d90/milestone2/publish-and-verify/offchain/egc/nodes/funder.py#L317
[strrepr]: https://github.com/jefdaj/electionguard-cardano/blob/6dff12e55f7225cc4ab777e0676888256c702d90/milestone2/publish-and-verify/offchain/egc/core/plutus/types/channel.py#L13
[sub]: https://github.com/jefdaj/electionguard-cardano/blob/6dff12e55f7225cc4ab777e0676888256c702d90/milestone2/publish-and-verify/offchain/egc/core/subscriber.py#L276
[ytdemo]: https://www.youtube.com/watch?v=Qe0vyI1Zazo
[yttour]: https://www.youtube.com/watch?v=Dr2lltC-zw0&pp=0gcJCUwLAYcqIYzv

Today I'm happy to announce that I'm (finally!) done with Milestone 2 of [my Fund13 project][f13].
As always, code is available [on Github][code].

It's been a while since I posted a dev update.
For a few months I've been focusing on the Cardano-related parts of the code and just mocking the election operations with pre-generated artifacts. This wraps that up; the smart contract and offchain code is officially working, and I can move on to an integrated demo.

I made companion videos for each section (below), and wrote up [a tour of the design so far][design].

Content here won't repeat all that. This is just a quick retrospective, somewhere to dump messy thoughts that didn't fit cleanly anywhere else.

# What's in the code for a node?

Video for this section [here][yttour].

I haven't seen many examples of fully open source, decentralized Cardano dApps;
I felt like I was inventing a lot of little bits of it myself as I went. Now I
want to point them out in case they help somebody working with [PyCardano][pyc]
in the future.

Potentially interesting things I ended up doing, in no particular order:

- Manually keeping [a section of the Python code][pytypes] in sync with the Plutus [Aiken types][aktypes]
- Packaging everything in [Nix flakes][flake] (optional of course)
- Using Aiken to [apply contract parameters][params] because PyCardano isn't doing it yet
- Doing a couple type hacks related to encoding/decoding
- Writing round-trip tests to verify the encoding/decoding
- Custom [transaction building logic][logic] to subtract fees from a pool of ADA traveling along with a state thread token, with no other wallet (change address) needed
- An [`ElectionSubscriber`][sub] class that manages a Kupo process and converts created/spent UTXO matches into typed state transitions ([`ChannelEvent`s][events])
- Testing almost everyhing stateful as a DAG of [PyTest fixtures][fixtures]: wallets, nodes, channel states, transactions
- Making the fixtures module scoped and one module = one test election
- Adding [`burn_test_tokens`][burn] and [`recover_all_collateral`][recover] features to catch tokens lost during broken tests

I also did at least one questionable thing that I'm NOT sure was helpful:

- [Hacking `__str__` and `__repr__`][strrepr] so I can round-trip generated Python source code

You may have a better time if you lean in to PyCardano's idea of `__repr__` being to/from JSON instead?

# Publish + Verify demo

Video for this section [here][ytdemo].

Not sure what to say about this part... maybe the most important thing is that having gone through a lot of effort to get all the pieces set up (see below), I surprised myself by really liking how simple the overall data flow turned out. It's like an idealized web framework: many events &rarr; central state &rarr; updated view. It worked the first time. And it's certainly much simpler than writing a distributed system that would converge to a central state reliably on my own without a blockchain.

So don't lose heart! This really is a good way of doing things, even if it's difficult sometimes.
