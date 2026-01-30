---
title: Encryption
description: How end-to-end encryption works in Ente Locker
---

# Encryption

Ente Locker uses end-to-end encryption to protect your data. This means your
information is encrypted on your device before being sent to our servers, and
only you can decrypt it.

## How encryption works

### Your data flow

1. You create or edit a document
2. Your device encrypts the data using your encryption keys
3. The encrypted data is uploaded to Ente's servers
4. When you need the data, it's downloaded to your device
5. Your device decrypts the data for you to view

### What is encrypted

Everything in Locker is encrypted:

- Document titles
- Document content
- Collection names
- Metadata
- Sharing information

## Encryption algorithms

Ente Locker uses industry-standard, audited encryption:

- **Encryption**: XChaCha20 and XSalsa20
- **Authentication**: Poly1305 message authentication code (MAC)
- **Key derivation**: Argon2id with high memory and computation parameters

These algorithms are implemented using
[libsodium](https://libsodium.gitbook.io/doc/), an externally audited
cryptographic library.

## Zero-knowledge architecture

Ente operates on a zero-knowledge model:

- **We never see your data**: Your encryption keys never leave your devices
- **We can't read your content**: Even if servers were breached, your data
  remains encrypted
- **We can't recover your data**: Without your password or recovery key, your
  data cannot be decrypted

## Key management

### Master key

Your master key is derived from your password. This key encrypts all your
other keys.

### Collection keys

Each collection has its own encryption key. This allows for secure sharing
without exposing your master key.

### Recovery key

Your recovery key is a 24-word phrase that can decrypt your master key. This
is the only way to recover your account if you forget your password.

## Security audits

Ente's apps have been audited by:

- **Cure53**: A prominent German cybersecurity firm
- **Symbolic Software**: Applied cryptography specialists
- **CERN**: Technical assessment

Read more about our [security audits](https://ente.io/blog/cryptography-audit/).

## Related FAQs

- [How is my data encrypted?](/locker/faq/security#locker-encryption-method)
- [Can Ente see my data?](/locker/faq/security#locker-zero-knowledge)
- [Is my data safe if Ente is breached?](/locker/faq/security#locker-breach-safety)
