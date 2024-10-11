---
title: What could blockchain voting look like?
tags: electionguard, blockchain, voting, utxo, cardano
toc: True
reminder: election-day.png
...

[eg-site]: https://www.electionguard.vote

When you picture the voting system of the future, it's probably on your phone. Right?
Unfortunately, although *blockchain* voting can be done securely today, *internet* voting is much harder.
So I'll sketch out a less ambitious in-person setup using a hypothetical blockchain-enabled version of [ElectionGuard][eg-site] instead.
It's a little different than the typical workflow today, but not that different. All the required tech already exists.
Phones are involved, but they won't be allowed into the voting booth.

_This is my own idea, and might need revision.
The ElectionGuard authors haven't reviewed or endorsed it._


# ID check & voting NFT

<img src="id-check.png" style="width:300px;"></img>

OK, so you're an average voter in the not-so-distant future.
You arrive at your local polling place and see there are three lines: one to check in, one to vote, and one to check out (mint your NFTs).
Simple enough. A screen on the wall monitors the blockchain and displays the number of voters currently voting at each polling place, along with percent of eligible voters who have already finished.

More interestingly, it also shows the number of audits done (500,000) and irregularities proven (0) so far,
along with the total fraud bounty available (\$100 million).

While waiting in the first line you download an update to your preferred voting app.
You trust this app because it's open source, audited, and endorsed by the state + your political party.
You also trust that the developers are interested in catching any funny business so they can get their share of the fraud bounty,
and in not damaging their reputation by missing something.

At the front of the line you hand your ID to a poll worker.
They check it against the state database, which confirms you're a registered voter who hasn't already voted in this election.
They mint a vote-in-progress NFT and send it to the wallet in your app. The number on the wall increments and you head for the voting line.

# Voting (no phones allowed)

<img src="voting-machine.png" style="width: 250px;"></img>

You flip through the official paper voter's guide, and also browse one published by a local news website on your phone. You haven't finished deciding how to vote when you get to the front of the line, but that's OK. You know this first time through won't be your real vote anyway.

You leave your phone in a lock box and step into a voting booth.
You randomly tap out some choices on the touchscreen, making sure to wait a few seconds each time so it plausibly seems like you're thinking. Then you hit "submit", take your printed QR code, and get back to your phone.

# Audit or cast?

Now the "fun" part: the Benaloh challenge. You actually think of it as a chore, but you do it anyway because you want the "I audited!" NFT, worth \$10 off groceries. The app scans the QR code, confirms that your vote is on chain, and presents the choice: audit or cast? You choose audit. It signs a transaction to that effect and adds it to the chain. A few seconds later, the voting machine responds by publishing the decryption key. You  check that your (public, invalidated) ballot looks as expected. Sadly, it does---no fraud bounty today. You get back in the voting line for another round.

<img src="check-ballot-before-challenge.png" style="width: 300px;"></img>

You can audit as many times as you want, since it's important for the voting machine not to know when you'll cast your final vote. But you're already bored, and each time you have to wait a little longer in line. So you stick with just the one audit.

OK, for real now. You finish circling your choices in the booklet. This time you fill the ballot out correctly and cast it. This also burns your vote-in-progress NFT. The voting machine responds by promising that it has destroyed the temporary decryption key. Now there's no way to know for sure that it encrypted your vote honestly. But you expect that it did because it couldn't have known whether you would choose to audit a second time.

# Mint personal NFTs

<img src="i-voted-nfts.png" style="width: 300px;"></img>

The last line moves quickly. Another poll worker traces the history of your vote-in-progress NFT and sends "I voted!" + "I audited!" NFTs to your personal wallet. They thank you for voting.

Besides getting \$10 off groceries, the NFTs will also validate your parking, and prove to your boss that you were out for an approved reason today.
In case you ever need to prove that you passed a state ID check, they'll work for that too.

# Verify the final tally

Nothing left to do now except get discounted groceries and watch the election play out on TV, or on one of the many dashboard websites. (The commentary varies, but they all agree on the numbers.)

Actually, you *could* verify the entire election yourself and post a proof of correctness to the blockchain relatively easily. But you don't bother. Only the first 100 done with each verifier implementation are eligible for "I verified" NFTs, up to 1000 total. And you know how people are---they'll post them seconds after the official tally is uploaded, just for the bragging rights.
Instead you just watch the deadline come and go, and the confirmations pour in.

# Vibe check

So that's the general workflow from an imaginary average voter's perspective. What's your reaction?

Personally, I would be annoyed with the gamification. But on reflection I would appreciate that incentives are necessary to get people to confirm that every aspect of the election is above board. There's still the choice not to vote, or to vote but not to bother with the NFTs, same as before. So it seems reasonable.

More importantly, I think that skeptical--even conspiratorially minded--voters, with no unusual math skills, could be convinced that their votes were counted honestly using a cryptographic system like this. It acknowledges that their fears are reasonable, then definitively puts them to rest. That's a huge improvement over the status quo!

(Remember, you're reading this in the future but it was posted 3 weeks before the 2024 US presidential election. It was a scary time! Almost everyone would have chosen to put up with extra bullshit in order to raise the odds of a peaceful transfer of power.)

# Time to build

There might be issues with the particular incentives imagined here, but IMO the major stumbling block is clearly the requirement for in-person voting. I hope we'll be able to tackle that soon.

In the meantime, let's get going on the version we know we can build! We don't need to invent any more cryptography first; at this point the most urgent research questions are around engineering, usability, and public education. And those are probably best answered by doing lots of small pilot studies.
