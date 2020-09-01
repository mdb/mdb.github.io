---
title: An intro to the GPG CLI
date: 2020/04/11
tags: gpg, encryption
thumbnail: TODO.png
teaser: An intro to using the GPG CLI
published: false
---

GPG (GNU Privacy Guard) is a free, open source version of the PGP (Pretty Good Privacy) encryption software. GPG is used to encrypt files containing sensitive information, such as passwords, using a method of encryption called public key cryptography.

While various GPG front end graphical user interfaces exists, `gpg` is its simple command line interface.

## Installation

Installation varies across operating systems and platforms. On Mac OS, I used [Homebrew](http://brew.sh/) to install GPG:

```
brew install gnupg
```

## Generate a key pair

To generate a keypair -- consisting of a private and public key -- enter the following command, providing your name and email at the prompts (generally, selection of the defaults at the other prompts will suffice for most use cases); provide a strong passphrase:

```
gpg --gen-key
```

Note that this creates a `~/.gnug` directory for housing your keys.

## Backups best practices

Your keys should be backed up, and your private key must never be shared. This is my backup strategy:

Export my personal public key to a `mikeball_public_gpgc.key` text file (replacing `email@example.com` with the real address associated with my personal `gpg` key):

```
gpg \
  --export \
  --armor \
  "email@example.com" > mikeball_public_gpg.key
```

Export my personal private key to a `mikeball_private_gpg.key` file (again, replacing `email@example.com` with the real address associated with my personal `gpg` key):

```
gpg \
  --export-secret-key \
  --armor \
  "email@example.com" > mikeball_private_gpg.key
```

Export my ownertrust to a `mikeball_ownertrust_gpg.txt` file:

```
gpg --export-ownertrust > mikeball_ownertrust_gpg.txt
```

Use `gpg` itself to encrypt my `mikeball_private_gpg.key` file, using `gpg`'s support of _symmetric encryption_. Unlike _assymetric_ encryption -- which requires a public and private keypair -- _symmetric_ encryption requires only a private key for both encryption and decryption. While symmetric encryption is less secure than assymetric encryption, This is necessary because, on a new system, the `` is For example, to encrypt the private key in a `mikeball_private_gpg.key.asc` file:

```
gpg \
  --encrypt \
  --armor \
  --symmetric \
  --local-user "email@example.com" \
  --recipient "email@example.com" \
  mikeball_private_gpg.key
```

Decrypt the file at a future date via the following command (you'll need to enter the passphrase associated with your key):

```
gpg \
  --decrypt \
  mikeball_private_gpg.key.gpg > mikeball_private_gpg.key
```

## Import a key pair

```
gpg --import mikeball_public_gpg.key
gpg --import mikeball_private_gpg.key
gpg --import-ownertrust mikeball_ownertrust_gpg.txt
```
