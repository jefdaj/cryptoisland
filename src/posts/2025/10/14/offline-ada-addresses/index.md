---
title: "Derive Cardano staking and receive addresses offline"
tags: cardano, bash, nix, nixos, offline, airgapped, midnight, airdrop
toc: false
...

[post]: /posts/2025/10/11/mngd-offline-signing-scripts-ada-eth
[code]: ./offline-ada-addrs.tar
[cs]: https://cardanoscan.io
[as]: https://adastat.net

This could be useful for a variety of purposes, but the immediate reason to post it is for anyone who has only their seed phrase (no synced online wallet), and wants to claim their NIGHT from the Midnight Glacier Drop.
If that's you, make yourself a NixOS live USB according to [my earlier post][post].
Then download and run [this code][code] in the live OS to get your addresses...

```.bash
# my scripts
tar -xvf offline-ada-addrs.tar
cd offline-ada-addrs

# cardano-wallet
tarball='cardano-wallet-v2025-03-31-linux64.tar.gz'
curl -L -O "https://github.com/cardano-foundation/cardano-wallet/releases/download/v2025-03-31/${tarball}"
tar -xvf "$tarball"

# DISCONNECT NETWORK HERE

# transfer files in
cp /your/usb/drive/ada-seeds/*-seed.txt ./seeds/

# run the script
./main.sh

# transfer files out
cp addrs/*-addrs.txt /your/usb/drive/ada-addrs/

# wipe seed phrases before leaving
shred -n3 -u seeds/*
```

The output files should look like this,
and the addresses should match what you would see in most wallets.
You can check them with a block explorer like [CardanoScan][cs] or [AdaStat][as].

```.txt
wallet name:
WALLETNAME

stake address:
stake1u...

receive addresses:
addr1q...
addr1q...
addr1q...
...
```

From there you can go back and follow the rest of [the earlier post][post].
You'll need to get your claim messages from the portal, then boot back into NixOS to sign them,
then go back to the portal a second time to submit everything.
