---
title: Security and privacy FAQ
description:
    Frequently asked questions about security and privacy of Ente Photos
---

# Security and privacy

## Can Ente see my photos and videos?

No.

Your files are encrypted with a key before they are uploaded to our servers.

These keys can be accessed only with your password.

Since only you know your password, only you can decrypt your files.

To learn more about our encryption protocol, please read about our
[architecture](https://ente.io/architecture).

## How is my data encrypted?

We use [libsodium](https://libsodium.gitbook.io/doc/)'s implementations
`XChaCha20` and `XSalsa20` to encrypt your data, along with `Poly1305` MAC for
authentication.

Please refer to the document on our [architecture](https://ente.io/architecture)
for more details.

## Where is my data stored?

Your data is replicated to multiple providers in different countries in the EU.

Currently we have datacenters in the following locations:

-   Amsterdam, Netherlands
-   Paris, France
-   Frankfurt, Germany

Much more details about our replication and reliability are documented
[here](https://ente.io/reliability).

## What happens if I forget my password?

You can reset your password with your recovery key.

If you lose both your password and your recovery key, you will not be able to
decrypt your data.

## Can I change my password?

Yes.

You can change your password from any of our apps.

Thanks to our [architecture](https://ente.io/architecture), you can do so
without having to re-encrypt any of your files.

The privacy of your account is a function of the strength of your password,
please choose a strong one.

## Do you support 2FA?

Yes.

You can setup two-factor authentication from the settings screen of the mobile
app or from the side bar of our desktop app.

## How does sharing work?

The information required to decrypt an album is encrypted with the recipient's
public key such that only they can decrypt them.

You can read more about this [here](https://ente.io/architecture#sharing).

In case of sharable links, the key to decrypt the album is appended by the
client as a [fragment to the URL](https://en.wikipedia.org/wiki/URI_fragment),
and is never sent to our servers.

Please note that only users on the paid plan are allowed to share albums. The
receiver just needs a free Ente account.
