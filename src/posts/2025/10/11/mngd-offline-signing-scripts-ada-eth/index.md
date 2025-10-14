---
title: "Midnight Glacier Drop offline signing scripts for ADA and ETH"
tags: cardano, ethereum, midnight, airdrop, bash, javascript, nix, nixos, offline, airgapped
reminder: pocketwatch.png
...

[mngd]: https://claim.midnight.gd
[csign]: https://github.com/gitmachtl/cardano-signer
[ethjs]: https://docs.ethers.org/v6/
[code-ada]: ./mngd-offline-sign-ada.tar
[code-eth]: ./mngd-offline-sign-eth.tar
[post]: /posts/2025/10/14/offline-ada-addresses


Today we'll be signing Glacier Drop claims offline with [cardano-signer][csign] and/or [ethers][ethjs].
I'm not claiming this is the only or best way; it's just a cleaned up version of what I did.
Please let me know ASAP if you notice anything dumb or insecure!

This guide assumes you have your wallet(s) synced up already,
but they aren't compatible with the Glacier Drop.
Maybe you still use Daedalus and don't want to additionally trust a web wallet with your seed phrases, for example.

_If you *only* have the seed phrases and no wallet set up,
you'll need to make a wallet or calculate a suitable destination address before making a claim message.
~~That's out of scope for this post but I'll write an update explaining it if anyone asks.~~ See [this post][post] for instructions._

You'll need two USB drives.


# Cardano workflow

## Gather info

If you have more than a couple wallets I recommend starting a spreadsheet to keep track:
wallet name, stake address, destination address, night allocation, thaw dates (fill in later).
You also need to make two text files per wallet: `WALLETNAME-claim.txt` for the unique claim message, and `WALLETNAME-seed.txt` for the seed (recovery phrase).

To get each claim message you'll need to go through the [claim portal][mngd] wizard up to the point where you're supposed to sign.
Instead, save the message to the text file and start over with the next wallet.

_YMMV, but I had to use Chrome (Chromium) because there were lots of JS errors in Firefox, and it wasn't able to download the PDF receipt at the end. Guess IOG isn't supporting it?_

Personally, I used the same unused receive address as both source and destination for each wallet.
The portal can figure out the stake address from there.
Then I double checked that it matched the stake address in the spreadsheet.
It would also be fine to set a different destination address if you want to gather your NIGHT in one wallet rather than keeping them separate.

The claims should look like this.

```.txt
STAR XXXXX to addr1qXXX...XXX 31a...b8b
```

Put them on some removable media to move to your offline signing environment.
Find your seed phrases too.


## Make a NixOS live USB

_This can be another distro if you already have a favorite.
See `shell.nix` in each tarball for approximate packages and JS setup commands._

```.bash
iso_url='https://channels.nixos.org/nixos-25.05/latest-nixos-graphical-x86_64-linux.iso'
wget "${iso_url}.sha256"
wget "${iso_url}"
sha256sum -c latest-nixos-graphical-x86_64-linux.iso.sha256
sudo dd if=latest-nixos-graphical-x86_64-linux.iso of=/dev/YOURDEVHERE status=progress && sudo sync
```

_Careful that you have the `dd` command worked out properly to avoid data destruction,
or write the ISO a different way._


## Set up offline environment

Boot into your live USB/DVD.
Set up networking via ethernet if possible, or wifi if not.
You want to be able to definitively disconnect it after installing the code.

Download and unpack [this tarball][code-ada],
then set up and test [cardano-signer][csign]:

```.bash
tar -xvf mngd-offline-sign-ada.tar
cd mngd-offline-sign-ada
git clone https://github.com/gitmachtl/cardano-signer
mv shell.nix cardano-signer/src/
cd cardano-signer/src
nix-shell
cd ../..

# check that it works
cardano-signer | less -R
```

Now disconnect the network!
(Install ETH code first too if needed)
Ideally you want to unplug the ethernet cable,
or maybe turn off your router?
If you're less paranoid, something like this might also be good enough:

```.bash
sudo systemctl stop NetworkManager
sudo rm -rf /etc/wpa_supplicant
```


## Sign claim messages

There are several scripts and sets of files,
but all the info you need to keep ends up in `portals/*.txt`.

```.bash
# DISCONNECT NETWORK HERE

# transfer files in
cp /your/usb/drive/ada-seeds/*-seed.txt   ./seeds/
cp /your/usb/drive/ada-claims/*-claim.txt ./claims/

# run the scripts
./1-keys.sh
./2-sign.sh # TODO adjust if needed
./3-portal.sh

# transfer files out
cp portal/*-portal-info.txt /your/usb/drive/

# optionally clean up before rebooting
./4-shred.sh
```

_If you're gathering all your NIGHT to one wallet,
comment out the line in `2-sign.sh` that asserts each destination address
belongs to the wallet generated from the corresponding seed phrase._


## Submit claims

The last step is to go back to [the portal][mngd] on your online computer.
Click through the wizard again for each wallet, giving the exact same answers to get the same claim message.
If you use a different destination address each time,
make sure it isn't auto-filling the previous one.
Double check that everything matches before submitting: destination address, allocation, claim message, stake key.

Each portal info file should look like this.

```.txt
midnight glacier drop claim info for WALLETNAME wallet

network:
cardano

destination addr:
addr1qXXX...XXX

claim message:
STAR XXXXX to addr1qXXX...XXX 31a...b8b

signature:
XXXXXXXXXXXXXXXXXXXXXXXXXXXXX...

pubkey:
XXXXXXXXXXXXXXXXXXXXXXXXXXXXX...
```

Paste the signature and pubkey, then sign + complete the claim.
I saved the PDF receipts and took screenshots too for good measure.

_Don't forget to also get rid of any temporary copies of your seed phrases,
especially on the USB drive. `shred -n3 -u` is an easy way._


# Ethereum workflow

The process for ETH is similar, except that you need to create a Cardano wallet to generate your destination address(es) first.
You could do that offline, but I assume most people won't bother; making an empty web wallet is easy and low risk.

The other difference is it works with 3 kinds of keys:

1. `WALLETNAME-seed.txt`
2. `WALLETNAME-keystore.json` + `WALLETNAME-password.txt`
3. `WALLETNAME-privatekey.txt`

Here's [the tarball][code-eth].

```.bash
# make a live USB and boot into NixOS as above

# install the code
tar -xvf mngd-offline-sign-eth.tar
cd mngd-offline-sign-eth
nix-shell

# DISCONNECT NETWORK HERE

# transfer files in
cp /your/usb/drive/eth-keys/* ./seeds-and-keys/
cp /your/usb/drive/eth-claims/*-claim.txt ./claims/

# run the script
./1-main.sh

# transfer files out
cp portal/*-portal-info.txt /your/usb/drive/

# optionally clean up before rebooting
./2-shred.sh
```

Portal info files should look like this.

```.txt
midnight glacier drop claim info for WALLETNAME wallet

network:
ethereum

origin address:
0xXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

destination address:
addr1qXXX...XXX

claim message:
STAR XXXXX to addr1qXXX...XXX 31a...b8b

signature:
XXXXXXXXXXXXXXXXXXXXXXXXXXXXX...
```
