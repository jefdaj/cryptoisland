---
title: ElectionGuard + blockchain integration ideas
tags: electionguard, blockchain, voting, incentives
updated: 2024-10-18
reminder: please-lock-door.png
toc: false
...

[eg-site]: https://www.electionguard.vote/
[phone-app]: /posts/2024/10/15/mechanics-of-the-benaloh-challenge/#cast-audit-via-phone-app
[self-certify]: http://localhost:8000/posts/2024/10/15/mechanics-of-the-benaloh-challenge/#self-certify-casts-audits

Welcome to the first in an ongoing series of posts about [ElectionGuard][eg-site]!
Some will explain how it works now, and some will also include ways I think it could be extended and integrated with a blockchain. I'll try to differentiate clearly between the two.

To read a linear series of posts, click the "electionguard" tag at the top.
To jump to particular topics instead, use the links below.

For now I mainly want to emphasize that although blockchains and related tech aren't required,
they could be used to strengthen the security and trustworthiness of almost every step.
When dealing with public elections, it's reasonable to add some redundant safeguards, after all...

Action|EG in Theory|EG in Practice|My Suggestion
-----|------|--------|-------
set election parameters|administrator via website + deployments |administrator via website + deployments|administrator via <b>blockchain</b>
set up physical infrastructure|administrator|administrator|administrator?
manage bulletin board|administrator|administrator|<b>blockchain</b>
host bulletin board|administrator via website|administrator via website|<b>decentralized</b> quardians + anyone via <b>IPFS</b>
publish live stats during election|NA|anyone on own websites|anyone on own websites
perform key ceremony|independent guardians|guardians following administrator|<b>decentralized</b> guardians
publish ballots, mark cast or spoiled|mediators via https?|mediators via https?|mediators (and [voters][self-certify]?) via <b>blockchain</b> + <b>IPFS</b>
verify inclusion of own vote|voter via website|voter via website|[voter via <b>blockchain + IPFS</b>][phone-app]
certify or dispute inclusion of own vote|NA|NA|[voter via <b>blockchain</b>][self-certify]
certify or dispute spoiled ballot decryption|NA|NA|[voter via <b>blockchain</b>][phone-app]
gather artifacts to verify|anyone via website|anyone via website + news/social media|anyone via <b>blockchain + IPFS</b>
publish verification|anyone via news/social media|anyone via news/social media|anyone via <b>blockchain</b>
publish fraud proofs|NA|anyone via news/social media|anyone via <b>blockchain</b>
perform audits|administrator + quorum of independent guardians|administrator + quorum of loyal guardians|administrator + quorum of <b>decentralized</b> guardians
tally encrypted votes|quorum of independent guardians|quorum of loyal guardians|quorum of <b>decentralized</b> guardians
decrypt votes during audits|quorum of independent guardians|quorum of loyal guardians|quorum of <b>decentralized</b> guardians using <b>blockchain random seed</b>
publish tally + audit results|administrator via website?|administrator via website?|<b>decentralized</b> guardians via <b>blockchain</b> + <b>IPFS</b>

Table: Who's responsible for each part of an election, and which tools do they use?
