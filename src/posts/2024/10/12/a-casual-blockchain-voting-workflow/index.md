---
title: A casual blockchain voting workflow
tags: electionguard, blockchain, voting, irl, brainstorm
toc: True
reminder: coolest-boat.png
...

[benaloh-challenge]: https://youtu.be/2TGtpUCNFPs?t=1362

Yesterday I laid out [a fairly hardcore workflow](../../11/gamified-blockchain-voting-from-a-voters-perspective/) that could be appropriate for nation state elections, and ended by suggesting that we should do lots of small pilot studies to start working out the incentives.

OK then... what if you want to run one of those pilot studies, but your use case is more casual?
Say you're planning a trip and want everyone who comes to the meeting on Tuesday to vote on where to go camping next weekend.
Or you're starting a homeowners' association and want to go door-to-door collecting votes for the first president.
(I don't know how HOAs work.)
Here's one possible streamlined version that might be appropriate.

The steps are similar to the full version, but this time all the equipment is handheld.
The "poll worker" (probably you) brings two devices:

* one for checking IDs, shown as a phone here
* one for filling out ballots

The devices could be combined, and the ID check could be skipped if you know everyone.

# Workflow

## Optional ID check

Either recognize the voter's face or look them up on your phone to confirm they should be voting.
Or, even easier, use an honor system and assume that everyone in the room will only vote once.

## Mint voter NFT

<img src="id-check.png" style="width: 200px; "></img>

Have the voter get out their app. (There should probably be an ElectionGuard demo web app they can try here!)
Mint them a vote-in-progress NFT, and explain that they'll fill out their ballot on a separate device and then cast or audit using the app.

## Fill out ballots

<img src="voting.png" style="width: 200px; "></img>

In a door-to-door situation, hand the voter the tablet and watch while they make selections.
In a casual meeting the tablet can be passed around the room.
Each voter makes their selections, confirms them, and then scans a QR code on their phone.
Meanwhile you can answer questions, checks IDs, give a talk, etc.

## Audit or Cast

The Beneloh challenge is the same as before: the voter confirms their vote, then decides whether to audit or cast. If cast, they're done. Otherwise they wait for the tablet to come back around and vote again. You might have to peer pressure an especially diligent auditor to give up at some point.

You'll need to explain it and possibly show [the video][benaloh-challenge] or do a quick demo.

<img src="challenge.png" style="width: 200px; "></img>

## Run tally

Close out the voting period (presumably in the demo app) and have the guardians run the tally.
Announce it publicly along with a URL to all the artifacts.

## Mint participation NFTs

Optional of course.
The type of people who might want to try this might also be keen to start building an on-chain reputation.
You can give an extra special one to anyone who downloads the artifacts and runs the verifier.

# Infrastructure

### Administrator

This is probably you. The main tasks are to coordinate the guardians and install stuff on a tablet + optional phone.

### Blockchain

The obvious thing to use here is a public testnet. It should be stable on short timescales, and you can send the voters free coins to pay all their fees.

### Guardians

If this is a somewhat-important vote, say for a corporate leadership position, it might be important to set up a set of proper decentralized guardians. They can be hired on chain, or designated through any process that voters agree sounds fair.

If it's just a meetup, you might ask for a couple volunteers at the beginning to run the guardian app in addition to the voter app. Or you could forgo the process entirely, losing the normal voter privacy properties.

Door-to-door canvassing is a little harder. Hiring on chain seems like the best option, or having a couple people in your organization set up beforehand if possible.
