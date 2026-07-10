---
title: "ElectionGuard + Cardano Dev Update #7: Publish + Verify"
tags: electionguard, cardano, catalyst, fund13, elections, python, docker, dev-update
reminder: publish-and-verify.png
updated: 2026-07-10
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
[prev]: /posts/2025/12/23/egc-dev03-election-tests

Today I'm happy to announce that I'm (finally!) done with Milestone 2 of [my Fund13 project][f13].
As always, code is available [on Github][code].

It's been a while since I posted a dev update.
For a few months I've been focusing on the Cardano-related parts of the code and just mocking the election operations with pre-generated artifacts. This wraps that up; the smart contract and offchain code is officially working, and I can move on to an integrated demo.

I made companion videos for each section (below), and wrote up [a tour of the design so far][design].

# Publish + Verify demo

Video for this section [here][ytdemo].

## `publish.sh`

The "publish" half just runs the tests from [happy_election.py](https://github.com/jefdaj/electionguard-cardano/blob/trunk/milestone2/publish-and-verify/offchain/tests/demo/test_happy_election.py). I decided to re-use them here because they already do everything it's supposed to do, and in a better way than I originally planned: it turns out a DAG of PyTest fixtures is the ideal way to pass around all the little bits of info needed to orchestrate supposedly separate nodes collectively carrying out an election. For example, the onboarding info that in real life will be done by QR codes:

```python
@per_election_fixture
def onboarding_info(
        subchannel_nodes: list[ElectionNode],
    ) -> dict[ChannelId, VerificationKeyHash]:
    info = {
        n.channel_id() : n.publisher.wallet.vkh
        for n in subchannel_nodes
    }
    return info

@per_election_fixture
def admin_tx2(
        admin_tx1: Transaction,
        admin: AdminNode,
        onboarding_info: dict[ChannelId, VerificationKeyHash],
    ) -> Transaction:
    ch_strs = [channel_id_to_string(k) for k in onboarding_info.keys()]
    LOG.info(f'admin got onboarding info from {', '.join(ch_strs)}')
    tx = admin.add_subchannels(
        subchannels = onboarding_info,
        subchannel_ada = 20,
        done_onboarding = True, # advance to ConfigCeremonyPhase
    )
    LOG.debug(f'admin_tx2: {tx}')
    admin.wait_for_confirmation(tx)
    return tx
```

The structure also matches the previous [Aiken tests](https://github.com/jefdaj/electionguard-cardano/blob/trunk/milestone2/publish-and-verify/onchain/validators/tests/integration/happy_election.ak) reasonably well. The main difference is that this time the tests have to be ordered chronologically rather than only by channel, because the nodes are actually talking to each other. Whereas in Aiken tests, only inputs and outputs matter.

I got pytest to reliably order them by making every TX a fixture and depending on it in the next one(s). For example you can see above that `admin_tx1` isn't used anywhere in `admin_tx2`, but it needs to come first so I make it a fixture argument.

## `verify.sh`

For this part of the demo I used an [`ElectionSubscriber`][sub]. There's already one of these per ElectionNode being run by the publish script, but I wanted to show that you can also use them independently as a lightweight way to monitor the election without participating in it.

The other new thing is that the pytest suite didn't deal with IPFS at all, so I needed to tack that on to make the demo. (Don't worry, I know IPFS syncing works in general based on [previous work][prev])

I started out trying to "tack it on" in a fairly lazy way, but actually ended up with more elegant code than I expected. There's:

- [ipfs.py](https://github.com/jefdaj/electionguard-cardano/blob/trunk/milestone2/publish-and-verify/offchain/egc/core/ipfs.py), which handles uploading and downloading
- [records.py](https://github.com/jefdaj/electionguard-cardano/blob/trunk/milestone2/publish-and-verify/offchain/egc/core/records.py), which translates `PublicRecordMetadata` to and from file paths
- [one line to upload the files before posting them to the blockchain](https://github.com/jefdaj/electionguard-cardano/blob/f138f0908bd8431bfaa94240afd2b1d471d26c4e/milestone2/publish-and-verify/offchain/egc/core/node.py#L170)
- a callback system in the subscriber that makes it [easy](https://github.com/jefdaj/electionguard-cardano/blob/f138f0908bd8431bfaa94240afd2b1d471d26c4e/milestone2/publish-and-verify/offchain/subscribe.py#L51) to print out events as they happen and download the files

Here's the minimal code you can add to a subscriber to have it fetch everything.
It's a little cleaner than the version in the actual script:

```python
PUB_DIR = './data/verifier2/public'

def fetch_to_static_records_dir(event: ChannelEvent):
    if not event.output_state:
        # ignore RmSubChannels, EndElection
        return
    new_records = event.output_state.state.new_records
    ipfs_fetch_records_to_file_sync(new_records, PUB_DIR)
```

After fetching files, the last step is just to run the old M1 verifier script. It did't require any changes, which is very reassuring.

``` bash
sudo docker exec publish-and-verify-verifier2-1 \
    poetry run /scripts/verifier.py verify \
    --public-dir /data/public \
    --verifier-id verifier2 \
    --logfile /data/private/verify.log
```

```txt
Verifying announcement:
✅ manifest
✅ ceremony_details

Verifying key ceremony:
✅ guardian_pubkey {'guardian_id': 'guardian_1'}
✅ guardian_pubkey {'guardian_id': 'guardian_2'}
✅ guardian_pubkey {'guardian_id': 'guardian_3'}
✅ guardian_backup {'guardian_id': 'guardian_1', 'backup_order': 2}
✅ guardian_backup {'guardian_id': 'guardian_1', 'backup_order': 3}
✅ guardian_backup {'guardian_id': 'guardian_2', 'backup_order': 1}

...

Verifying ballot ID sets:
✅ 6 ballots spoiled = 6 ballots decrypted
✅ 6 ballots cast + 6 ballots spoiled = 12 ballots submitted
✅ set(spoiled ballot IDs) = set(decrypted ballot IDs)
✅ set(cast ballot IDs) + set(spoiled ballot IDs) = set(submitted ballot IDs)

Verifying final tally:
✅ ciphertext_tally format is valid
✅ ciphertext_tally is the correct aggregation of the 6 cast ballots
✅ plaintext_tally format is valid
✅ plaintext_tally guardian decryption shares are valid

...

Final tally of cast ballots:

Should pineapple be banned on pizza?
  3 Unsure
  2 No
  1 Yes

🎉 The election has been verified!
```


# What's in the code for a node?

Video for this section [here][yttour].

_The video is a reasonably well done tour, but this section of the post is just a quick retrospective, somewhere to dump messy thoughts that didn't fit cleanly anywhere else._

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

Not sure what else to say... maybe the most important thing is that having gone through a lot of effort to get all the pieces set up, I surprised myself by really liking how simple the overall data flow turned out. It's like an idealized web framework: many events &rarr; central state &rarr; updated view. It worked the first time. And it's certainly much simpler than writing a distributed system that would converge to a central state reliably on my own without a blockchain.

So don't lose heart! This really is a good way of doing things, even if it's difficult sometimes.
