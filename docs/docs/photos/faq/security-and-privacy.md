---
title: Security and Privacy FAQ
description: Comprehensive information about security and privacy measures in Ente Photos
---

# Security and Privacy FAQ

Welcome to Ente Photos' Security and Privacy FAQ. This document provides
detailed information about our security practices, privacy measures, and how we
protect your data. We are committed to maintaining the highest standards of data
protection and transparency.

## Data Encryption and Storage

### Can Ente see my photos and videos?

No. Your files are encrypted on your device before being uploaded to our
servers. The encryption keys are derived from your password using advanced key
derivation functions. Since only you know your password, only you can decrypt
your files. For technical details, please see our
[architecture document](https://ente.io/architecture).

### How is my data encrypted?

We use the following encryption algorithms:

- Encryption: `XChaCha20` and `XSalsa20`
- Authentication: Poly1305 message authentication code (MAC)
- Key derivation: Argon2id with high memory and computation parameters

These algorithms are implemented using
[libsodium](https://libsodium.gitbook.io/doc/), a externally audited
cryptographic library. Our [architecture document](https://ente.io/architecture)
provides full technical specifications.

### Where is my data stored?

Your encrypted data is stored redundantly across multiple providers in the EU:

- Amsterdam, Netherlands
- Paris, France
- Frankfurt, Germany

We use a combination of object storage and distributed databases to ensure high
availability and durability. Our
[reliability document](https://ente.io/reliability) provides in-depth
information about our storage infrastructure and data replication strategies.

In short, we store 3 copies of your data, across 3 different providers, in 3
different countries. One of them is in an underground fall-out shelter in Paris.

### How does Ente's encryption compare to industry standards?

Our encryption model goes beyond industry standards. While many services use
server-side encryption, we implement end-to-end encryption. This means that even
in the unlikely event of a server breach, your data remains protected.

## Account Security

### What happens if I forget my password? {#account-recovery}

If you are logged into Ente on any of your existing devices, you can use that
device to reset your password and use your new password to log in.

If you are logged out of Ente on all your devices, you can reset your password
using your recovery key that was provided to you during account creation.

If you are logged out of Ente on all your devices and you have lost both your
password and recovery key, we cannot recover your account or data due to our
end-to-end encrypted architecture.

If you wish to delete your account in such scenarios, please reach out to
support@ente.io and we will help you out.

### Can I change my password?

Yes, you can change your password at any time from our apps. Our architecture
allows password changes without re-encrypting your entire library.

The privacy of your account is a function of the strength of your password,
please choose a strong one.

### Do you support two-factor authentication (2FA)?

Yes, we recommend enabling 2FA for an additional layer of security. We support:

- Time-based One-Time Passwords (TOTP)
- WebAuthn/FIDO2 for hardware security keys

You can set up 2FA in the settings of our mobile or desktop apps.

## Sharing and Collaboration

### How does sharing work?

The information required to decrypt an album is encrypted with the recipient's
public key such that only they can decrypt them.

You can read more about this [here](https://ente.io/architecture#sharing).

In case of sharable links, the key to decrypt the album is appended by the
client as a [fragment to the URL](https://en.wikipedia.org/wiki/URI_fragment),
and is never sent to our servers.

Please note that only users on the paid plan are allowed to share albums. The
receiver just needs a free Ente account.

## Security Audits

## Has the Ente Photos app been audited by a credible source?

Yes, Ente Photos has undergone a thorough security audit conducted by Cure53, in
collaboration with Symbolic Software. Cure53 is a prominent German cybersecurity
firm, while Symbolic Software specializes in applied cryptography. Please find
the full report here: https://ente.io/blog/cryptography-audit/

## Account Management

### How can I delete my account?

You can delete your account at any time by using the "Delete account" option in
the settings. For security reasons, we request you to delete your account on
your own instead of contacting support to ask them to delete your account.

Note that both Ente Photos and Ente Auth data will be deleted when you delete
your account (irrespective of which app you delete it from) since both photos
and auth use the same underlying account.

To know details of how your data is deleted, including when you delete your
account, please see https://ente.io/blog/how-ente-deletes-data/.

## Additional Support

For any security or privacy questions not covered here, please contact our team
at security@ente.io. We're committed to addressing your concerns and
continuously improving our security measures.
