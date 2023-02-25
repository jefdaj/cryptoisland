---
title: How I generated my GPG keys
tags: security, gpg, encryption
...

Everyone agrees that [GnuPG][gpg] has a difficult interface, and therefore you
need to follow various guides to get stuff done. But they're often *really*
detailed! So here's a somewhat-less-detailed guide, intended to get you
set up as quickly as possible without missing anything important.

But first, one request: I'm breaking with "best practices" a bit in
that most people would advise you not to show the commands you used in case it
helps an attacker. That smells of [security through obscurity][sto] to me, and
I think the value of sharing outweighs the risk. But if you do spot a mistake,
please [contact me][about] so I can update this post rather than hacking me!

With that out of the way, here are the steps I used to set up and share [my own
keys][pubkey]. I found it easier to run through everything multiple times with
new temporary `--homedir`s than to understand the options before trying them.
If you decide you want more background reading though, start with these:

* [samuelexferri's gpg guide][guide]
* [a StackExchange post about master key and subkeys][sep]

# Generate keys

The key generation command is interactive. Everything after `#` is an answer to
a prompt which should be clear in context.

~~~{ .bash }
$ mkdir -p offline-gpghome
$ alias GPG='gpg --homedir=offline-gpghome --keyid-format=long'
$ GPG --expert --full-generate-key # 8, s, e, q, 0, y, no password, name, email, no comment
$ GPG --expert --edit-key jefdaj
> addkey # 4, 4096, 1y, y, y, no password
> addkey # 6, 4096, 1y, y, y, no password
> addkey # 8, a, s, e, q, 4096, 1y, y, y, no password
> save
~~~

That created one master `[C]`ertification key and separate subkeys for
`[S]`igning, `[E]`ncryption, and `[A]`uthentication:

<!-- TODO sketch of keys: [e]mail, [s]ignature, [a]? and a seal for [c] -->

~~~{ .bash }
$ GPG --list-keys
/tmp/generate-gpg-key/offline-gpghome/pubring.kbx
-------------------------------------------------
pub   rsa4096/E604517174B3D49E 2021-09-28 [C]
      54C195A345205DCABC2010EEE604517174B3D49E
uid                 [ultimate] EMAIL REDACTED TO REDUCE SPAM
sub   rsa4096/EF8F01E8B5D49300 2021-09-28 [S] [expires: 2022-09-28]
sub   rsa4096/73B356CD3CA9E12B 2021-09-28 [E] [expires: 2022-09-28]
sub   rsa4096/6E123E190F5FB8BD 2021-09-28 [A] [expires: 2022-09-28]
~~~

The certification key never expires, and will be treated like a [cold
wallet][cold]: I'll have to dig it out of my offline backups once per year to
extend or replace the other 3, or to certify anyone else's public key
(confusingly referred to as "key signing" even though you use the `[C]` key).

<!-- TODO sketch of burying the seal -->

# Make offline backups

Next I export backups of all the keys.

~~~{ .bash }
$ mkdir offline-backup
$ GPG --armor --export-secret-keys    > offline-backup/secret-keys.asc
$ GPG --armor --export-secret-subkeys > offline-backup/secret-subkeys.asc
$ GPG --armor --export                > offline-backup/public-keys.asc
~~~

These will be stored offline and encrypted.

I also generate revocation certificates. They will be backed up too, but more
importantly I'll keep copies on hand to import and upload to keyservers
in case I get hacked.

~~~{ .bash }
$ for keyid in EF8F01E8B5D49300 73B356CD3CA9E12B 6E123E190F5FB8BD; do
>   GPG --output offline-backup/revoke-${keyid}.asc --gen-revoke ${keyid}
> done # answer for each: y, 1 (compromised), y
~~~

The master certification key probably won't be hacked, but it should be
revocable in case I lose my online backups. So I generate a certificate for
that too. I'll store it separately from the main backups.

~~~{ .bash }
$ GPG --output offline-backup/revoke-E604517174B3D49E.asc --gen-revoke E604517174B3D49E # y, 0 (no reason), y
~~~

# Verify backups

First the public keys. We're checking for `pub` in front of the master key,
`sub` in front of each subkey, and that `--list-secret-keys` doesn't list
anything.

~~~{ .bash }
$ mkdir verify-public
$ gpg --homedir=verify-public --import offline-backup/public-keys.asc
gpg: keybox '/tmp/generate-gpg-key/verify-public/pubring.kbx' created
gpg: /tmp/generate-gpg-key/verify-public/trustdb.gpg: trustdb created
gpg: key E604517174B3D49E: public key "EMAIL REDACTED TO REDUCE SPAM" imported
gpg: Total number processed: 1
gpg:               imported: 1
~~~

~~~{ .bash }
$ gpg --homedir=verify-public --list-keys --keyid-format=long
/tmp/generate-gpg-key/verify-public/pubring.kbx
---------------------------------------------
pub   rsa4096/E604517174B3D49E 2021-09-28 [C]
      54C195A345205DCABC2010EEE604517174B3D49E
uid                 [ unknown] EMAIL REDACTED TO REDUCE SPAM
sub   rsa4096/EF8F01E8B5D49300 2021-09-28 [S] [expires: 2022-09-28]
sub   rsa4096/73B356CD3CA9E12B 2021-09-28 [E] [expires: 2022-09-28]
sub   rsa4096/6E123E190F5FB8BD 2021-09-28 [A] [expires: 2022-09-28]
~~~

~~~{ .bash }
$ gpg --homedir=verify-public --list-secret-keys --keyid-format=long
~~~

Now the secret subkeys. Look for `sec#` in front of the master key, meaning
that you only have the *public* half available. You should have the private
parts of the subkeys though, which is indicated with `ssb`.

~~~{ .bash }
$ mkdir verify-subkeys
$ gpg --homedir=verify-subkeys --import offline-backup/secret-subkeys.asc
gpg: keybox '/tmp/generate-gpg-key/verify-subkeys/pubring.kbx' created
gpg: /tmp/generate-gpg-key/verify-subkeys/trustdb.gpg: trustdb created
gpg: key E604517174B3D49E: public key "EMAIL REDACTED TO REDUCE SPAM" imported
gpg: To migrate 'secring.gpg', with each smartcard, run: gpg --card-status
gpg: key E604517174B3D49E: secret key imported
gpg: Total number processed: 1
gpg:               imported: 1
gpg:       secret keys read: 1
gpg:   secret keys imported: 1
~~~

~~~{ .bash }
$ gpg --homedir=verify-subkeys --list-secret-keys --keyid-format=long
/tmp/generate-gpg-key/verify-subkeys/pubring.kbx
----------------------------------------------
sec#  rsa4096/E604517174B3D49E 2021-09-28 [C]
      54C195A345205DCABC2010EEE604517174B3D49E
uid                 [ unknown] EMAIL REDACTED TO REDUCE SPAM
ssb   rsa4096/EF8F01E8B5D49300 2021-09-28 [S] [expires: 2022-09-28]
ssb   rsa4096/73B356CD3CA9E12B 2021-09-28 [E] [expires: 2022-09-28]
ssb   rsa4096/6E123E190F5FB8BD 2021-09-28 [A] [expires: 2022-09-28]
~~~

Finally the secret keys. Everything should look the same except `#` should
be gone from `sec` on the master key:

~~~{ .bash }
$ mkdir verify-secret
$ gpg --homedir=verify-secret --import offline-backup/secret-keys.asc
gpg: keybox '/tmp/generate-gpg-key/verify-secret/pubring.kbx' created
gpg: /tmp/generate-gpg-key/verify-secret/trustdb.gpg: trustdb created
gpg: key E604517174B3D49E: public key "EMAIL REDACTED TO REDUCE SPAM" imported
gpg: key E604517174B3D49E: secret key imported
gpg: Total number processed: 1
gpg:               imported: 1
gpg:       secret keys read: 1
~~~

~~~{ .bash }
$ gpg --homedir=verify-secret --list-secret-keys --keyid-format=long
/tmp/generate-gpg-key/verify-secret/pubring.kbx
---------------------------------------------
sec   rsa4096/E604517174B3D49E 2021-09-28 [C]
      54C195A345205DCABC2010EEE604517174B3D49E
uid                 [ unknown] EMAIL REDACTED TO REDUCE SPAM
ssb   rsa4096/EF8F01E8B5D49300 2021-09-28 [S] [expires: 2022-09-28]
ssb   rsa4096/73B356CD3CA9E12B 2021-09-28 [E] [expires: 2022-09-28]
ssb   rsa4096/6E123E190F5FB8BD 2021-09-28 [A] [expires: 2022-09-28]

~~~

<!-- TODO also check the revocation certificates? -->

# Make online subkeys

Next I set passwords to protect the subkeys in case they're stolen from my
online computer...

~~~{ .bash }
$ for keyid in EF8F01E8B5D49300 73B356CD3CA9E12B 6E123E190F5FB8BD; do
>   GPG --pinentry-mode loopback --passwd $keyid
> done # ignore error message, enter new passphrase twice
~~~

... and re-export the password-shielded versions.
I also copy over the revocation certificates.

~~~{ .bash }
$ mkdir online-pc
$ GPG --armor --export-secret-subkeys > online-pc/secret-subkeys.asc
$ cp offline-backup/revoke-*.asc online-pc/
$ rm online-pc/revoke-E604517174B3D49E.asc
~~~

*Note: I didn't use passwords on the backups above because they will already be
encrypted. Trying to set them here revealed a bug in `pinentry`'s handling of
empty passwords! I worked around it using `--pinentry-mode loopback` as
suggested [here][bug].*

# Final checks

After a bit of cleanup, these are the files I'll be keeping:

~~~{ .bash }
$ rm -r offline-gpghome verify-*
$ tree
.
├── offline-backup
│   ├── public-keys.asc
│   ├── revoke-6E123E190F5FB8BD.asc
│   ├── revoke-73B356CD3CA9E12B.asc
│   ├── revoke-E604517174B3D49E.asc
│   ├── revoke-EF8F01E8B5D49300.asc
│   ├── secret-keys.asc
│   └── secret-subkeys.asc
└── online-pc
    ├── revoke-6E123E190F5FB8BD.asc
    ├── revoke-73B356CD3CA9E12B.asc
    ├── revoke-EF8F01E8B5D49300.asc
    └── secret-subkeys.asc

2 directories, 12 files
~~~

`file` reports that the pubkeys are public keys, the revocation certificates
are signatures, and the secret keys are ASCII.

~~~{ .bash }
$ file */*
offline-backup/public-keys.asc:             PGP public key block Public-Key (old)
offline-backup/revoke-6E123E190F5FB8BD.asc: PGP public key block Signature (old)
offline-backup/revoke-73B356CD3CA9E12B.asc: PGP public key block Signature (old)
offline-backup/revoke-E604517174B3D49E.asc: PGP public key block Signature (old)
offline-backup/revoke-EF8F01E8B5D49300.asc: PGP public key block Signature (old)
offline-backup/secret-keys.asc:             ASCII text
offline-backup/secret-subkeys.asc:          ASCII text
online-pc/revoke-6E123E190F5FB8BD.asc:  PGP public key block Signature (old)
online-pc/revoke-73B356CD3CA9E12B.asc:  PGP public key block Signature (old)
online-pc/revoke-EF8F01E8B5D49300.asc:  PGP public key block Signature (old)
online-pc/secret-subkeys.asc:           ASCII text
~~~

Seems reasonable. I'm ready to back up the raw keys and move the shielded
subkeys to an online computer!

# Import and publish

I import the secret subkeys, which also include the corresponding public ones.

~~~{ .bash }
$ gpg --import online-pc/secret-subkeys.asc
$ gpg --list-secret-keys
/home/jefdaj/.gnupg/pubring.kbx
-------------------------------
sec#  rsa4096 2021-09-28 [C]
54C195A345205DCABC2010EEE604517174B3D49E
uid           [ unknown] EMAIL REDACTED TO REDUCE SPAM
ssb   rsa4096 2021-09-28 [S] [expires: 2022-09-28]
ssb   rsa4096 2021-09-28 [E] [expires: 2022-09-28]
ssb   rsa4096 2021-09-28 [A] [expires: 2022-09-28]
~~~

Just to be sure, I confirm the `sec#` and 3 `ssb`s again. I save the revocation
certificates somewhere too.

There are lots of confusing options for where to publish a key these days.
After reading [this][servers] I decide to export to a file and [upload it to
keys.openpgp.org][upload] manually.

~~~{ .bash }
gpg --armor --export 73B356CD3CA9E12B > 73B356CD3CA9E12B.asc
~~~

I expected that would only export the `[E]`ncryption subkey, but turns out
everything is bundled together. I'm OK with that. If you aren't you
could `--edit-key` to delete the ones you don't want to publish first,
then re-import them.

Once they're uploaded (and my email is verified) I can [search][search] for
them by key fingerprint or email, or fetch by fingerprint using gpg only:

~~~{ .bash }
gpg --keyserver keys.openpgp.org --recv-key 54C195A345205DCABC2010EEE604517174B3D49E
~~~

[about]:   /about.html
[bug]:     https://unix.stackexchange.com/a/597949
[cold]:    https://www.pcmag.com/encyclopedia/term/cold-wallet
[gpg]:     https://gnupg.org/
[guide]:   https://github.com/samuelexferri/gpg-guide/blob/master/gpg-guide.md
[pubkey]:  /about/jefdaj.asc
[search]:  https://keys.openpgp.org
[sep]:     https://security.stackexchange.com/a/186685
[servers]: https://superuser.com/questions/227991/where-to-upload-pgp-public-key-are-keyservers-still-surviving
[sto]:     https://en.wikipedia.org/wiki/Security_through_obscurity
[upload]:  https://keys.openpgp.org/upload
