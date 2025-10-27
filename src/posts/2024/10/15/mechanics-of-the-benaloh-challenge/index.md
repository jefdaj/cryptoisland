---
title: Mechanics of the Benaloh Challenge
tags: electionguard, blockchain, voting, incentives, brainstorm, encryption
reminder: boring-card-trick.png
updated: 2024-10-29
...

[eg-video]: https://youtu.be/2TGtpUCNFPs?t=1583
[eg-site]: https://www.electionguard.vote

# Motivation

In [ElectionGuard][eg-site] and related end-to-end encrypted voting systems,
the Benaloh challenge is a clever answer to the question
"How can voters check that their votes were encrypted honestly, without also being able to show how they voted to others?"

If you're thinking about this for the first time, you might have another question now: why do we care if they show how they voted?
Let's deal with that first, then get back to how it can be done.

## Why do we care?

Strong ballot secrecy (being unable to show your vote to others) might sound like a minor issue,
but it turns out to be essential for overall election integrity.
Without it voters are vulnerable to all sorts of coersion:

* mob bosses deciding how neighborhoods will vote
* company bosses pressuring employees
* family members pressuring each other
* social media harassment campaigns
* retaliation by an incoming or outgoing government

Basically, unless votes are kept private, people tend to vote for their own immediate personal safety rather than for good government.

## How is it done?

The best way I've seen it explained is [as a boring card trick][eg-video].
Here's the algorithm:

1. Ask the voter if they'd like to vote "red" or "black" this time.
2. Give them a card of the chosen color, face-down, and ask whether they want to audit or cast that vote.
3. If they audit, flip the card over (decrypt it) to prove it was the right color, and start again at step 1.
4. If they cast, they're done. The face-down card is their real vote.

The voter can't be certain that the final card represents their choice,
but they can tell that the dealer would have a hard time reliably cheating without being caught.

In a real election, the dealer (voting system) would be caught in at least one lie with overwhelming probability if it tried to change enough votes to alter the results.
The statistics are very impressive! I'll do another post about them specifically.
So although each voter only gets a weak guarantee that own their vote was correct, they can have strong confidence in the overall election outcome.

# Current mechanics

## Overview

OK, that's a very neat abstract trick!
How can it be implemented as part of the voting process?
This varies because [ElectionGuard][eg-site] is a toolkit that can be used in flexible ways,
but generally there would be 3 stations set up at the polling place.
You start with an ID check,
then go through the voting + challenge stations as many times as you want,
finishing you when choose to cast your real vote:

~~~{ lang="dot-as-svg" }
digraph current_workflow {
  rankdir=TB
  bgcolor=transparent
  node [shape=box, style="rounded,filled", fillcolor=lightgreen]
  edge [color=grey]

  Enter [shape=plain,fillcolor=transparent]
  Leave [shape=plain,fillcolor=transparent]
  subgraph cluster_votingbooth {
    bgcolor="#fbeee0"
    label="Voting Booth"
    submit_ballot [label="Scan & submit ballot"]
    fill_out_ballot -> submit_ballot
  }
  subgraph cluster_checkin {
    bgcolor="#fbeee0"
    label="Check-in Station"
    id_check [label="ID check"]
    fill_out_ballot [label="Fill out paper ballot"]
    id_check -> fill_out_ballot
  }
  subgraph cluster_challenge {
    bgcolor="#fbeee0"
    label="Challenge Station"
    audit_or_cast [label="Benaloh challenge:\naudit or cast?",fillcolor="#66ddff"] // blue
  }
  // TODO separate post
  // subgraph cluster_verify {
  //   label="verify tally"
  //   verify_vote_included -> verify_tally
  // }
  Enter -> id_check
  submit_ballot -> audit_or_cast [label="Publish\ncyphertext"]
  audit_or_cast -> fill_out_ballot [label="Audit", weight=0]
  // audit_or_cast -> verify_vote_included [label="cast"]
  audit_or_cast -> Leave [label="Cast"]
  // verify_vote_included -> Leave
  // verify_tally -> Leave
}
~~~

In practice most voters decline to do even one audit,
so they sail straight through without much additional friction compared to the regular (unencrypted) voting experience.

<!--
Whether you audit or not, each vote comes with a confirmation code that can be used to look it up on the election website later.
Voters can verify that their real vote was included in the final tally.
Audited ballots are decrypted + posted publicly instead, so everyone can see what they would have been if cast.
-->

The next few subsections go through how each step works now in more detail.
Then I'll explain some blockchain upgrades that I think would improve them,
and finally deal with a couple new complications those upgrades would introduce.

## ID check

This is done the traditional way, by checking your name against a state database.
The poll worker confirms you're an eligible voter who hasn't already voted in this election.

## Fill out paper ballot

This can be done in any of the traditional ways, or new ones:

* fill it out manually
* select options on a touchscreen
* audio instructions + voice recognition
* get help from a human
* ...

<img src="ballot.png" style="width:300px"></img>

The important thing is that you end up with a paper record that can be used to settle any disputes about the electronic process.

It should be done in a "publicly private" setting to guard against others seeing your choices,
as well as against yourself recording them on video.
That's also traditional.

## Scan & submit ballot

This should also be done in a publicly private setting.
It could be the same booth but is probably separate for efficiency.
(Filling out the ballots takes longer, so there should be more stations for that.)

From the voter's perspective this step is fast: a machine scans your ballot, keeps it, and prints a confirmation code.
You might optionally get a chance to confirm on screen that everything was scanned correctly first.

Keeping it is important, both for disputes and to prevent you from showing someone how you voted later.

The ballot is encrypted + uploaded to the "public bulletin board" (normally a website run by the election administrator).
The confirmation code includes a hash of the posted ciphertext, so you can check later that it hasn't been altered.

<img src="submit-ballot-500.png" style="width:400px"></img>

_Note that I made up this particular machine. What they look like varies by jurisdiction._

<!--
This step is simple from the voter's perspective, but it's where a lot of the ElectionGuard magic happens.
-->

### Gotcha: encryption nonce

This is the most confusing part.
There's a vulnerability in the encryption step,
and by solving it we also end up discovering a way to verify audited ballots.
This is the first half of the story:

After converting the ballot to a vector of `0`s and `1`s representing empty and marked bubbles respectively,
the scan & submit machine uses public key encryption (think GPG) to encrypt it.
Only a quorum of guardians (see separate post) will be able to decrypt it using their private key shares,
and they've agreed to do that only as part of an audit---either an individual voter's audit as described below, or an official risk-limiting statistical audit of the whole election.

So the vote should be unreadable under normal circumstances.
The "gotcha!" is that the machine also has to include a random number (called a nonce for "number used once"),
because otherwise there would only be so many possible permutations of the ballot (2 in my pirate example),
and people could generate a lookup table to "decrypt" votes without having the private key:

~~~{ .txt }
encrypt("Blackbeard" , guardians_pubkey) = 408756345
encrypt("Squawks III", guardians_pubkey) = 673209582
~~~

The nonce prevents that by making all the encryptions different, even when they encode the same choices:

~~~{ .txt }
encrypt( ("Blackbeard", 8273423), guardians_pubkey ) = 408756345
encrypt( ("Blackbeard", 7823942), guardians_pubkey ) = 984729344
encrypt( ("Blackbeard", 1982131), guardians_pubkey ) = 982374823
~~~

<!-- TODO is it really standard GPG style, or is there any more nuance to it? -->

<!-- TODO explain nonce here with pic (or code? talk slide?) -->

## Benaloh challenge: audit or cast?

Challenge time!
At this point the voting machine already publicly committed to your encrypted vote, but you haven't said whether you want to audit or cast it. (Note that you should have decided that for yourself *before* filling out the ballot. Otherwise you'll be publishing your real choices as part of the audit.)

I believe this step is sometimes done at the same scan & submit machine, and sometimes at a separate station networked to the first one. Perhaps the main advantage of a separate station is that a human can explain the choice, and then either direct you out of the voting area or back into line depending whether you audit?

Either way, now we get to the other half of the nonce story: if you choose to audit, the scan & submit machine will also publish the nonce on the bulletin board. The rule is that any ballot whose nonce was published should be individually decrypted during the final tally, and *not* counted as a real vote.

## Audit verification

Why publish the nonce rather than just a message saying not to count that ballot? It provides a nifty mechanism for voters to decrypt the audited ballot for themselves before the final tally: they just try encrypting all permutations with that nonce until they find one that matches the published ciphertext. The bug becomes a feature!

This isn't part of the current polling place experience; diligent voters are encouraged to do it from home.
In fact I don't think v1 of ElectionGuard implements at all. It's planned for v2 though.

<!-- TODO cite that -->

## End-to-end verification

After the official election results are published, the diligent voter can also download all the artifacts from the bulletin board and use independent verifier software to further confirm that:

#. All ballots were well-formed
#. The final tally is correct
#. Their own cast ballot was included in the tally
#. All audited ballots were decrypted, and their own look as expected

<img src="home-laptop.png" style="width: 250px;"></img>

I won't linger on it here, but verification is a huge advantage over traditional elections!
Even without any of the "upgrades" I'm going to go on about, it's 100% worth implementing ElectionGuard or something similar at scale to get these properties.

## How are disputes handled?

I'm not sure if there's any standard process for disputing an audit result or a missing ballot ciphertext in the current workflow.
I imagine, though, that any such challenge would have to be resolved by going to the press, pressuring the election authority to address it, and eventually doing a recount of the original paper ballot under independent supervision.


# Proposed blockchain upgrades

In the workflow I'm imagining, the first few steps would be roughly the same as above:

1. Show ID at the check-in counter
2. Fill out a paper ballot (possibly using a machine) in a voting booth
3. Submit the ballot and get a printed confirmation code (hash of the posted cyphertext)

<!--
The only difference so far is that in my system you would get a "vote in progress" NFT after the ID check.
-->

## Cast & audit via phone app

The main change I'm proposing is that after submitting the paper ballot, instead of going to a "challenge station" or finishing that on the same scan/submit machine, you scan the QR code and finish the process on your own phone---or laptop, I suppose. It would be done using the voter's favorite of hopefully many independently developed and audited voting apps.

I know I know, everything has to be an app these days. I normally hate that!
But in this case there are some major advantages.
Now the voter has a trusted device that can do cryptographic operations on their behalf, which means:

1. We can add a second step to the Benaloh challenge where we immediately decrypt audited ballots, and either certify or dispute the result.
2. We can broadcast each step in the protocol on chain, and watch everyone else doing it in real time.

From the voter's perspective the challenge workflow is still pretty simple:

<img src="audit-certify-dispute.png" style="width: 600px;"></img>

The back end protocol becomes a little more complicated, but not too bad.
`S:` here means something is being posted on chain by the "system", and `V:` means something is posted on chain by the voter's trusted app.


~~~{ lang="dot-as-svg" }
digraph proposed_workflow {
  rankdir=TB
  bgcolor=transparent
  node [shape=box, style="rounded,filled", fillcolor=lightgreen]
  // edge [color=grey]

  Enter [shape=plain,fillcolor=transparent]
  Leave [shape=plain,fillcolor=transparent]
  Enter -> id_check
  subgraph cluster_checkin {
    label="Check-in Station"; labelloc="b"
    bgcolor="#fbeee0"
    // id_check -> mint_vip_nft
    id_check [label="ID check"]
  }
  subgraph cluster_votingbooth {
    label="Voting Booth"
    bgcolor="#fbeee0"
    fill_out_ballot [label="Fill out paper ballot"]
    submit_ballot [label="Scan & submit ballot"]
    fill_out_ballot -> submit_ballot
  }
  subgraph cluster_app {
    label="Trusted Voting App"; labelloc="b"
    bgcolor="#fbeee0"
    node [fillcolor="#66ddff"] // blue
    confirm_onchain [label="Scan QR code &\nfind ciphertext"]
    submit_ballot -> confirm_onchain [label="S:Publish\ncyphertext"]
    confirm_onchain -> audit_or_cast
    audit_or_cast [label="Benaloh challenge:\naudit or cast?",fillcolor="#66ddff"] // blue
    decrypt_ballot [label="Decrypt & check:\ndoes ballot look right?"]
    rank=same {audit_or_cast,decrypt_ballot}
    tmp1 [shape=point,style=invis]
    audit_or_cast -> tmp1 [label="V:Audit"]
    tmp1 -> decrypt_ballot [label="S:Publish\nnonce"]
    rank=same {audit_or_cast,tmp1,decrypt_ballot}
    tmp2 [shape=point,style=invis]
  }
  // TODO separate post
  // subgraph cluster_checkout {
  //   label="check-out station"
  //   mint_personal_nfts
  // }
  // subgraph cluster_dispute {
  //   label="arbitration"
  //   dispute -> open_ballot_box -> id_check
  // }
  // TODO separate post
  // subgraph cluster_verify {
  //   label="verifier app"
  //   verify_tally -> mint_verifier_nft
  // }
  id_check -> fill_out_ballot [label="S:Vote in\nprogress"]
  // audit_or_cast -> mint_personal_nfts [label="cast"]
  audit_or_cast -> tmp2 [label="V:Cast"]
  tmp2 -> Leave [label="S:Delete\nnonce"]
  decrypt_ballot -> id_check [label="V:Certify"]
  decrypt_ballot -> id_check [label="V:Dispute"]
  // id_check -> mint_personal_nfts [style="dashed"] // Leave without voting
  // mint_personal_nfts -> verify_tally
  // mint_personal_nfts -> Leave
  // mint_verifier_nft -> Leave
}
~~~

## Self-certify casts & audits

Rather than communicating with the voting system locally via touchscreen or a poll worker, the choice to audit or cast should be publicly announced on chain. You control your own phone app and the blockchain is independent, so there's no plausible way for the voting system to interfere with your choice or know about it in advance.

IMO this new version would be fun for voters and would probably cause the amount of challenges to rise dramatically.
It would feel like doing something, having a real choice, challenging the state etc.

## Immediate, public audit results

Another advantage is that you can immediately download the encrypted ballot from the bulletin board website and/or blockchain. If the voting machine also publishes the nonce (random number) used to encrypt, the app can use that to "brute force" all possible ballot selections until it finds the one that matches the ciphertext. That way, you can confirm that the encrypted choices look right. You should then have the additional choice to publicly certify that they do, or publicly launch a dispute (have someone look at the paper ballot). Being able to see everyone else doing this on chain will raise confidence in the system.

## Live statistics

All these certifications on chain add up to vastly improved real-time data, which can be published fast enough to head off any misinformation about the election. In my opinion that's the real secret sauce! Reliable, immediate proof that there's no large scale fraud that could plausibly be changing the results of the election.

I'll leave it at that for now, because it's such an important point that it deserves its own post.

<img src="dashboard.png" style="width:300px"></img>

# Handling new complications

## On-chain privacy

It's important to note that you would *not* be linking your identity to your voting actions on chain. That could be dangerous if your vote is selected for decryption during a risk limiting audit.

Instead, I'm proposing that the voting app generate a new wallet/address per vote. After you show your ID at the check-in counter, the poll worker would send a "vote in progress" NFT to the wallet authorizing it to vote.

That's why in my version you have to revisit the check-in station each time you vote: you're getting a new NFT.
On chain, everyone sees a series of anonymous-but-authorized NFTs going through the voting steps.
They're created by the poll worker and burned by the voter during `cast`, `certify`, and `dispute` actions.

Optionally, there could be a final "Mint Rewards" station where a poll worker reads the history of your voting actions from your app and sends rewards to your personal wallet without connecting them to anything else on chain: "I voted", "I audited", "\$10 reward", etc.

## Dispute collateral?

You could imagine a situation where disgruntled voters might "DDoS" the system by auditing and then baselessly disputing every ballot.
To prevent that, you could simply limit the number of audits per person. That seems reasonable.
But another possibility would be to have voters post collateral each time so frivolous disputes cost money.
I don't think it would be fair to require people to pay to audit, but it might be reasonable to pay everyone for voting, and ask that they risk the reward money to launch a dispute. Of course, if they actually catch the system cheating there should be a much larger reward!
I would have to think about this more before having a strong opinion about the best mechanism.

<!-- TODO a simulation game where you try to cheat would also be a really good idea! -->
<!-- TODO could also promote actual red teaming via hacker events, but not sure about that -->
