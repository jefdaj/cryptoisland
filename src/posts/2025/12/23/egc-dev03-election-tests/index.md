---
title: "ElectionGuard + Cardano Dev Update #3: Election Tests"
tags: electionguard, cardano, catalyst, fund13, elections, nix, python, docker, arion, linux, dev-update
reminder: ogre.png
...

[atpy]:  https://github.com/jefdaj/electionguard-cardano/tree/trunk/milestone1/tests/scripts/attack.py
[bchal]: /posts/2024/10/15/mechanics-of-the-benaloh-challenge
[code]:  https://github.com/jefdaj/electionguard-cardano/tree/trunk/milestone1/tests
[dev]:   /posts/2025/12/23/egc-dev01-election-demo/#dev-options
[egpy]:  https://github.com/jefdaj/electionguard-python
[eljs]:  https://github.com/jefdaj/electionguard-cardano/tree/trunk/milestone1/tests/election.json
[elsh]:  https://github.com/jefdaj/electionguard-cardano/tree/trunk/milestone1/tests/election.sh
[f13]:   https://milestones.projectcatalyst.io/projects/1300090
[hypo]:  https://hypothesis.readthedocs.io/en/latest/
[prev]:  /posts/2025/12/23/egc-dev02-election-verifier
[test]:  https://github.com/jefdaj/electionguard-cardano/tree/trunk/milestone1/tests/test.sh
[yt]:    https://www.youtube.com/watch?v=BuqPbmf5Ko4

This is dev update #3 for [my fund13 project][f13].
You can find the code [here][code], and a companion YouTube video [here][yt].

Today I'm excited to show a little more systematic suite of tests to verify that
the elections I'm running work with a variety of parameters, and
can withstand some hypothetical attacks. This isn't meant to be a comprehensive
security audit or cover the game theory or anything like that; it's mainly
meant to catch straightforward coding errors.


# How to run elections

I plan to make this part of the main codebase going forward,
so I kept the single election entrypoint and added a new one for tests.

## Single Election

Edit [election.json][eljs] and run [election.sh][elsh] to try things.

```bash
cd electionguard-cardano/milestone1/tests
nix develop
./election.sh
```

There's one new `attacks` field, which we'll get to below.
The [old dev options][dev] also still work.

The other change is that the admin, guardians, and independent verifiers automatically do their own verifications now. The admin's takes the place of the separate official summary JSON I used in the first version.

```bash
$ tree data/public/4_verify
data/public/4_verify
├── admin_1.json
├── guardian_1.json
├── guardian_2.json
├── guardian_3.json
└── verifier_1.json
```

## Test Suite

More interestingly, [test.sh][test] uses [Hypothesis][hypo] to generate
arbitrary election configs, runs the corresponding test elections, and verifies
some properties of the output files. The elections can be slow (2.5 hours to
run 143 of them on my laptop), but it caches the output files so at least
editing and re-running the property tests is fast.

```bash
cd electionguard-cardano/milestone1/tests
nix develop
./test.sh
```

```txt
============================= test session starts ==============================
platform linux -- Python 3.12.11, pytest-8.3.5, pluggy-1.5.0 -- ...
... collected 51 items

election.py::test_json_voteconfig <- config.py PASSED                    [  1%]
election.py::test_json_contestconfig <- config.py PASSED                 [  3%]
election.py::test_json_electionconfig <- config.py PASSED                [  5%]
election.py::test_json_attackcfg <- config.py PASSED                     [  7%]
election.py::test_json_honestrun <- config.py PASSED                     [  9%]
election.py::test_json_attackrun <- config.py PASSED                     [ 11%]
election.py::test_honest_always_verified PASSED                          [ 13%]
election.py::test_honest_all_verifiers_agree_exactly PASSED              [ 15%]
election.py::test_honest_n_verifications_matches_cfg PASSED              [ 17%]
election.py::test_honest_cast_votes_match_config PASSED                  [ 19%]
election.py::test_honest_spoiled_votes_match_config PASSED               [ 21%]
election.py::test_honest_manifest_verified PASSED                        [ 23%]
election.py::test_honest_ceremony_details_verified PASSED                [ 25%]
election.py::test_honest_gather_announce_verified PASSED                 [ 27%]
election.py::test_honest_all_guardian_backups_verified PASSED            [ 29%]
election.py::test_honest_all_guardian_verifications_verified PASSED      [ 31%]
election.py::test_honest_gather_ceremony_verified PASSED                 [ 33%]
election.py::test_honest_joint_key_verified PASSED                       [ 35%]
election.py::test_honest_build_election_verified PASSED                  [ 37%]
election.py::test_honest_constants_verified PASSED                       [ 39%]
election.py::test_honest_context_verified PASSED                         [ 41%]
election.py::test_honest_gather_constants_verified PASSED                [ 43%]
election.py::test_honest_all_devices_verified PASSED                     [ 45%]
election.py::test_honest_gather_config_verified PASSED                   [ 47%]
election.py::test_honest_all_ballots_submitted_verified PASSED           [ 49%]
election.py::test_honest_all_ballots_cast_verified PASSED                [ 50%]
election.py::test_honest_all_ballots_spoiled_verified PASSED             [ 52%]
election.py::test_honest_all_spoiled_results_verified PASSED             [ 54%]
election.py::test_honest_n_spoiled_decrypted_verified PASSED             [ 56%]
election.py::test_honest_n_cast_spoiled_submitted_verified PASSED        [ 58%]
election.py::test_honest_set_spoiled_decrypted_verified PASSED           [ 60%]
election.py::test_honest_set_cast_spoiled_submitted_verified PASSED      [ 62%]
election.py::test_honest_ballot_sets_verified PASSED                     [ 64%]
election.py::test_honest_ciphertext_tally_verified PASSED                [ 66%]
election.py::test_honest_tally_aggregation_verified PASSED               [ 68%]
election.py::test_honest_plaintext_tally_verified PASSED                 [ 70%]
election.py::test_honest_tally_decryption_verified PASSED                [ 72%]
election.py::test_honest_gather_tally_verified PASSED                    [ 74%]
election.py::test_honest_gather_decryptions_verified PASSED              [ 76%]
election.py::test_honest_gather_election_verified PASSED                 [ 78%]
election.py::test_attack_admin_withhold_manifest PASSED                  [ 80%]
election.py::test_attack_admin_ghost_after_vote PASSED                   [ 82%]
election.py::test_attack_device_withhold_submitted_ballot PASSED         [ 84%]
election.py::test_attack_device_withhold_cast_ballot PASSED              [ 86%]
election.py::test_attack_device_withhold_spoiled_ballot PASSED           [ 88%]
election.py::test_attack_device_mutate_submitted_ballot PASSED           [ 90%]
election.py::test_attack_device_mutate_spoiled_ballot PASSED             [ 92%]
election.py::test_attack_guardian_withhold_tally_share PASSED            [ 94%]
election.py::test_attack_guardian_withhold_spoiled_share PASSED          [ 96%]
election.py::test_verifiers_notice_attacks PASSED                        [ 98%]
election.py::test_attacks_are_logged PASSED                              [100%]

======================= 51 passed in 9118.83s (2:31:58) ========================
```

```txt
$ tree -L 2 tests
tests
├── test01ac1
│   ├── data
│   ├── election.json
│   └── election.log
├── test02b86
│   ├── data
│   ├── election.json
│   └── election.log
├── ...
└── testffd9e
    ├── data
    ├── election.json
    └── election.log

287 directories, 286 files
```

As you can see, each test is like the single elections we've been looking at so far.
They're deterministic (random seeds based on config file hashes), so you can delete one and re-run the tests to have the same config recreated and run again.

_Side note: the tests could probably be sped up significantly by running them in parallel.
I didn't do that yet because I wanted to make sure they all pass before introducing any potential issues related to interactions between Docker networks._

# What's tested?

Besides some small details like round-tripping config files, the main things are:

* for any honest (non-attacked) election, the verifiers should verify a bunch of properties
* for any attacked election, the verifiers should fail to certify `gather_election`
* for specific types of attacks, there are specific additional DAG nodes that should fail to verify
* some attacks cause certain phases of the election to be skipped, but verifiers should always run at the end

## Honest Runs

The most important properties being verified here are probably that the verifiers always certify honest elections, and the final tally always equals the cast votes from the JSON config.

```python
@given_honest_election()
def test_honest_gather_election_verified(testdir: ElectionTestDir):
  assert_verifiers_verified(testdir, 'gather_election')
```

```python
@given_honest_election()
def test_honest_cast_votes_match_config(testdir: ElectionTestDir):

    cfg = load_config_json(testdir)
    expected_cast_totals = cast_vote_totals_from_config(cfg)

    # admin isn't special here; could use any verifier
    summary = load_summary_json(testdir, 'admin_1')
    actual_cast_totals = sorted(summary['Final tally of cast ballots'])

    assert len(expected_cast_totals) == len(actual_cast_totals)
    for (expected, actual) in zip(expected_cast_totals, actual_cast_totals):

        assert set(expected['answers'].keys()) == set(actual['answers'].keys())

        for (answer, n_actual) in actual['answers'].items():
            assert n_actual == expected['answers'][answer]
```


## Attack Runs

Just as import important, and probably more fun, are the attack tests! Here are the ones I've written so far:

```python
ATTACKS = { 
    'admin_ghost_after_vote'          : {'who': 'admin', 'when': ['tally', 'decrypt_results']},
    'admin_withhold_manifest'         : {'who': 'admin', 'when': ['build_manifest']},
    'device_mutate_spoiled_ballot'    : {'who': 'device', 'when': ['vote_reveal_all']},
    'device_mutate_submitted_ballot'  : {'who': 'device', 'when': ['vote_commit_all']},
    'device_withhold_cast_ballot'     : {'who': 'device', 'when': ['vote_reveal_all']},
    'device_withhold_spoiled_ballot'  : {'who': 'device', 'when': ['vote_reveal_all']},
    'device_withhold_submitted_ballot': {'who': 'device', 'when': ['vote_commit_all']},
    'guardian_withhold_spoiled_share' : {'who': 'guardian', 'when': ['decrypt_shares']},
    'guardian_withhold_tally_share'   : {'who': 'guardian', 'when': ['decrypt_shares']},
}
```

The way they're implemented is that in the main `election` function in [election.py][elpy],
I've added an optional attack after each step.

```python
def election(cfg, log):
    try:
        build_manifest(cfg, log)        ; attack_all(cfg, log, 'build_manifest')
        announce_key_ceremony(cfg, log) ; attack_all(cfg, log, 'announce_key_ceremony')
        key_ceremony_round1(cfg, log)   ; attack_all(cfg, log, 'key_ceremony_round1')
        key_ceremony_round2(cfg, log)   ; attack_all(cfg, log, 'key_ceremony_round2')
        key_ceremony_round3(cfg, log)   ; attack_all(cfg, log, 'key_ceremony_round3')
        publish_joint_key(cfg, log)     ; attack_all(cfg, log, 'publish_joint_key')
        build_election(cfg, log)        ; attack_all(cfg, log, 'build_election')
        add_devices(cfg, log)           ; attack_all(cfg, log, 'add_devices')
        ids = vote_commit_all(cfg, log) ; attack_all(cfg, log, 'vote_commit_all')
        vote_reveal_all(cfg, log, ids)  ; attack_all(cfg, log, 'vote_reveal_all')
        tally(cfg, log)                 ; attack_all(cfg, log, 'tally')
        decrypt_shares(cfg, log)        ; attack_all(cfg, log, 'decrypt_shares')
        decrypt_results(cfg, log)       ; attack_all(cfg, log, 'decrypt_results')
    except Exception as e:
        print(e)
    finally:
        verify(cfg, log) ; attack_all(cfg, log, 'verify')
```

Attacks are listed by name in [election.json][eljs]. When `attack_all` is called with the relevant step,
it randomly corrupts one of the containers with the relevant role and has it run an attack function from [attack.py][atpy]. Then the rest of the election continues normally.

## Example "mutate" attack

Let's look at one particular attack I think is cool, and that helps give some
confidence the cryptography is working as intended. Here's the implementation.

```python
# election.py
@given_attacked_election('device_mutate_submitted_ballot', max_examples=50)
def test_attack_device_mutate_submitted_ballot(testdir: ElectionTestDir):
    assert_verifiers_reject(testdir, [
        'all_ballots_submitted',

        # The tally will still validate if the mutated ballot
        # was spoiled rather than cast, so this may work:
        # 'ciphertext_tally',

        'gather_election',
    ])

# scripts/attack.py
@announce_attack
def device_mutate_submitted_ballot(log, pubdir, privdir, step):
    submitted_ballots = set(d['ballot_id'] for d in list_submitted_ballot_fmtargs(pubdir))
    own_ballots       = set(d['ballot_id'] for d in list_own_ballot_fmtargs(privdir))
    valid_choices = [{'ballot_id': i} for i in own_ballots.intersection(submitted_ballots)]
    ballot_fmtargs = random.choice(valid_choices)
    mutate_public_record_crypto_in_place(
        log, pubdir, 'ballot_submitted',
        [

            # These can be changed without verifiers noticing:
            # 'description_hash',
            # 'manifest_hash',
            # 'pad',

            # These can't:
            'challenge',
            'crypto_hash',
            'data'
            'proof_one_data',
            'proof_one_pad',
            'proof_one_response',
            'proof_zero_data',
            'proof_zero_pad',
            'proof_zero_response',

        ],
        **ballot_fmtargs
    )
```

Attack calls are logged in the main election log, and more detailed logs are
available in the private data of the corrupted container.

```txt
# election.log
### attack ###

docker exec testbea22-device2-1 poetry run /scripts/attack.py attack --public-dir /data/public --private-dir /data/private --logfile /data/private/attack.log --attack-fn device_mutate_submitted_ballot --step vote_commit_all --random-seed 62058

# data/private/device_2/attack.log
### running device_mutate_submitted_ballot ###

targeting /data/public/2_ballots/1_submitted/ballot-ba77bc54-df81-11f0-a9fc-32689d655a73.json
there are 31 matching keys
targeting match 6, proof_one_response
mutated char 22: 9 -> 6
old: BA796CFF96207D51E84852955ED4719023799ED479F5F86271F6AC7E9696C87D
new: BA796CFF96207D51E84852655ED4719023799ED479F5F86271F6AC7E9696C87D
overwrote /data/public/2_ballots/1_submitted/ballot-ba77bc54-df81-11f0-a9fc-32689d655a73.json

### finished device_mutate_submitted_ballot ###
```

As you can see it targets a specific device, then a submitted ballot, then a crypto field within that ballot, and a character in that field. It changes that one character to a different random hex value and saves the file.

This is admittedly a biologist's approach to cryptography, but hey it works!
Hypothesis generates up to 50 election configs with that attack in them, runs the elections, and asserts that the verifiers always catch the error.

They do, and they give a reassuringly reasonable (if long) error message:

```json
{                                                                                                          
    "ballot_submitted": {                                                                                              
      "ballot-ba77bc54-df81-11f0-a9fc-32689d655a73": "chaum_pedersen.py.is_valid:#L114: found an invalid Disjunctive Ch
aum-Pedersen proof: {'in_bounds_alpha': True, 'in_bounds_beta': True, 'in_bounds_a0': True, 'in_bounds_b0': True, 'in_b
ounds_a1': True, 'in_bounds_b1': True, 'in_bounds_c0': True, 'in_bounds_c1': True, 'in_bounds_v0': True, 'in_bounds_v1'
: True, 'consistent_c': True, 'consistent_gv0': True, 'consistent_gv1': False, 'consistent_kv0': True, 'consistent_gc1k
v1': False, 'k': 'E02A3CB1BAD36433B3357541B946B2BA791428A0B870A0D4A048B64025B2BFD365C5C0874EF9A9DE65808BC9AB458A6815CD7
1A9B2F290B486EBD141DEC7ED40647379B1A4431B12353E84F40D989AD1B127992E88FA8C273FF1706F4B736CDF45DFF70959F5CA4088256620E4AC
BA3E62172B5F4F53FE8CFE9664F5C965887686C66F3CB679F7BF497EF025CCC4F49C56DEF9AC6DA73537D4C85ED35D1E1C3E6E30B7215CB2C207A90
07178C1F1E20A58D466F53340E445220D034B612EDA7D37DEC72B6C4F63C2F775358B32AFC221366DFE256B2BA5EC1CEDDB183823329FF0CB9C68FD
42B679FCD792411712E955B10BD6BA9AEEE3C6CB898075744AB70FDBD7241618EA6644BEF1E94BB10CB995F641915BE625330B29929BCF3B1C0010A
527502469CF86475DFA1BF155ADC4D146E7ECF62691137329D5EADF4D6089327CAF5FEC77C9A122BB905D818418CEBB13102E5CD8823949775DADAA
4A4715B19B749C43ECD7BD13A1432DBFC977CDBDE0595F1CC6F9098E0226000DDD2B035DA458D11C2899A8A9FE36B3066A347D971B15EB0CC045C4B
E5727F29468FAD0467E6A7676C76A3A8220CD02E3A59013B31C22E8078F4638D59361DC726A312ECAC1D09F22874023E0C2EF7F52C2C51E460EE989
C4E64E832271F32F06BB74BC5514B8B3163709E65029DA46CBCBEC0262768781B87D7F01843DBBFFA19C2E7BDE', 'proof': DisjunctiveChaumP
edersenProof(proof_zero_pad='9994F4B2E5F5C6AA5A0EE7B5042C96FEA1231DC87A474D2A658FF8FFA01334F78688013A8D1F2E8D9B5F6B6201
70D40A12B166B1E3F59227F9336B01B8E664E032088758295A89BDCDDF8B3029695742C881A0FF833181C06DD27671DF6FD21561DF97B06203D8F67
04AD0DAFD82CA053E9882B67AA3752FCC45D79E87FC3F130410A5D66794695E3C67F7D4F82A816D3812BA0E780351900B525D94CDCA208861830987
095E22F04E5035B05F65A31D66292682A1FD0EC61D257DD0A21E8846BAADCF6F7057AE06236B7881726D8FC4D833557D8154A00D5F7CDE21D843058
65E1C8661D196EB32369137D0C2F149BF2C42AE1927DD43813BFAD71E0C8A1EF7BA058C5A4E47B42BD2E5C490ED2F090FFFFEC9755F4E4DED1FD428
8AC797290701FDDE425E36AE2E116D30BF2B6389F25CBE7C7366C68F3E4260F09E31C5FDBA6CC4EF3BD80DF9970CC69E594C003D5403F6F351957D7
2672A04DF01DA764EA51490329A3C330187DBAA67F33BD2F0F409DDD78E5E452E1FE34F1767021BD77FC1AC62C3A2F3CD1F54E263AA91363B2F2252
40F1E3F317B87CBA9806E148E3AEA61910EF29AAD1A2992BB988F6C78E44BFB16277D3FD5A09F7F5A3C66E9F0E8F2965279128D647A6653D08020D9
92083DDA80D9CE44276A9F457C25CA7AC8EBC894E4479540C81C540B95381E54A73D2F5BCE9C7E0DB68BD444835988759B8D3', proof_zero_data
='ED6BE23226ED3B1B863CCC9D675A60E1C050700AAE44050197B0AE710A9C6CD99611F9AD2862D31D4CBDCA81361E29BA3A40C13A9383A7AD6BFDC
7FAE9BAC9136E680AE09272A31A24A93646614E8B4A8D2913D6DCF5A1586B2D938B6D2BFA9407744C6600712A99C75CA15079B63B89855CC20ED305
F1F4D92C071738C54F2A5379C1D8602BA3D9CA6CA798B0AE0B8E61E08E16621DC93F70FBBFEA4919BDEFF03580A9BC54768DB81BA24BFA66FB97BAB
3BF694739AB7BAF25400EA9E6878C5FBC26ECE97400C8E5A947BC936F1CA009B79AB2686D663DE16E76CD15436E75E4EEF8644C23B5D203095C318B
BC7CD4F0CE581382CB3D84678C5DB8AE75B778EE1858845B97C57F3809DE570C2EC356FF28D4AE6A6E7193A9AA370703088F12998FB1ACBD71AA237
A8E051ECE15C7891D00E29A3CE390344B4A153C21A179CA086EE0B0194A1D3661C0481DFC41C3AE59371A4B4DD598D2BF4FEF835FD1079374673377
5E74C23C851BE1795429148A416F9D1807B6B96830F8EF0B47E982894D51CF2B4DE933A43FA7BB9A52C92F9CE5405E704C58E100F102D26A95558F1
724B7F39E5AE1B405FC13289949F7E6B84BC22B132FB60925A3402C1544E17C8E110ECF19BD4573C05811CAE10A8AD482268B861B59C82B9F156357
891A9CA5B0A8D59003220A2D3C9EC1D22A118AB7EEB407433427F95D737E6CE34B2C20E154', proof_one_pad='4F6FE8E88B79B0C82F48247305C
4302ACD9AA8FA5050A517D7ED473FFDF8C129E50AF31B0482C586A16B4DF4E7DDDC0677BBB1C78F1F0E4B9256630CAC74144CCA5954D621D1CC347EF
ED3D13A39D3556FBE9023C17EAD2E77CDC96F7BD9C8C0FCEC8D934F02702B01C85DEE0C67B1F4C167F4D00931F4B7B918268CCCE4351261333F2C90E
1D9FC89BA86086CE1B0D828F4A9B9F2982F7A538ACAA74390237EFDDA83F2ECC3B960606050663E087AB9F2FE51139AE9831FC8418DA4D74AFFF20A4
E09F336B3A17FE33F21CD7403EC1B049FBEBF3EBE00A17386E2082675A3AA74E9E171779D027D7F658F2C46858C8A586A3787F4BF6DEDB185DCC8BF0
C547B695D7E5C3DEC654074F19F79100FB67B3D82E360B5E69F00C6CC1D26520F699929B509DEB690CA639912718574886D845811196E89BB589F4C4
F755943302D704ED4EB31A84E5A78F0D4D9C1AB3AA0E3C58DF0C59CE140E4047EC5303C300443F0A94C3391B6DAE4DC5C01BFCF9F8D7F146BD767CAF
5AE3365D365A385023BAACD23294B4D41B86ADFDF61319808BD809027ACE7399E555E4D32505433C3E14F87B7CBFEC49FA3B12FEE90C924B303C306F
7BE9EA1F3EFB47AFB56B5583CAA9938609C5636184A5E8FE8E6586E0A34E1112957296DE96874488DAF85CE1A2B21CA81765D5DDF0862AFEFEB6A179
E66DEC9F110B3F0B7C819CF5841D91F0997E2', proof_one_data='9D47AA0A0C4F7E948594C8C0898B18CE46922F1DB97D15C0E7001DDF571DCB60
3FA20CF667A1D422A0B69C3978DA1FCE209F27F6C5BE9A3D81A6E241FF40C068DB43B8CEB933C95F5CB71CEB98AA1841B8A10215B043861E4785F04E
FD54FB87C20541C3C4066735E97104FD1AC4C6101258F28FF6CE1DC0B4335AA5A1CA059C559584E867C4EE38A83919196E655734169E153F069B1993
013862C95DAFBEEA73BFFFC5640692C2AB744F7036D54E71D9DFC4457C8FF000EBE60213BA0035B7258E9AB812822AB47AB1A5B84CBB4CD4C51C615E
D0FB07C6310D98465EB031C8C3FFDAD52BB994C86C9773D4927AE9AA89B124764047B8EBC8F0FB1019D292E242F40881EBAF61E2937EA2536DF4F3B8
9CE3B42F99AFD53DEF6086358BD080639997A4498BE84345A81A1C24B6E822F30187024FF1FFA60A50D48404A6BD96C0E2CFD82E7182602BBA01A5D8
A188B5A829964396C70D4316050C8A694DE17C7CC32B66AE88AE276CE37C05ECF54E0319627F96F572127556319E3395D0D539DC06AF17F8E11225CA
6807F5CA0E23C14C7CB85B2E58D9B65401EA2F3FC4DA19CD00ACC36F66880A097A282D9F9CF7A88F1AFE7E82AE370ACFDDAB7A368ABB0898EB0544F1
392D6E42D2BD904A4931FD6BACB9FD1CC7A6DD6440729042F153C4A962FA3B54BF214F917CB77A6433E820675DBE4B2C6535D70C6F9932CAA293543D',
proof_zero_challenge='A29D945FF0E85DFB371DD51FE7ED6962D1C5AACF7F571B1557B69FCF9EE5999E', proof_one_challenge='44DD7A11F2
26AC02D72AC6A7DA7ABE8AF00111832AB512F95DF72F1E72782600', challenge='E77B0E71E30F09FE0E489BC7C26827EDC1C6BC52AA0C2E0EB5AD
CEEE115DBF9E', proof_zero_response='6A4B3ECBBB601F0DB1D49EA22D1888667706D0BD3C19D850CE48511EBC93EAA1', proof_one_respons
e='BA796CFF96207D51E84852655ED4719023799ED479F5F86271F6AC7E9696C87D', usage=<ProofUsage.SelectionValue: \"Prove selectio
n's value (0 or 1)\">)}\nballot_validator.py.ballot_is_valid_for_election:#L30: ballot_is_valid_for_election: mismatchin
g ballot encryption ballot-ba77bc54-df81-11f0-a9fc-32689d655a73"
    },
```

# What's *not* tested?

These test can catch some things, but as I said above, they're not comprehensive.
One important thing that they can't test for by design is whether the encryption devices are honestly encrypting the right votes or changing them.

For example, say I'm trying to vote for Alice. The encryption device says "OK, here's your encrypted vote for Alice." But it actually broadcasts a (properly) encrypted vote for Bob.

<img src="baddevice.png" style="max-width: 600px"></img>

There's no way to test for that without keeping a list of who each voter voted for, and that would violate ballot secrecy.
Instead, ElectionGuard has separate mechanisms to catch it:

* the [Benaloh challenge][bchal] (the "cast or spoil" thing)
* risk-limiting audits

That's all for today. Happy Holidays!
The next dev update will be about publishing election artifacts via IPFS.
