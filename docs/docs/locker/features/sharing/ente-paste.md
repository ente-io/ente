---
title: Ente Paste
description: Share sensitive text with one-time, end-to-end encrypted links
---

# Ente Paste

Ente Paste lets you share short sensitive text (keys, snippets, notes) using a
one-time, end-to-end encrypted link.

Open [paste.ente.io](https://paste.ente.io), paste your text, and share the
generated link.

## How it works

1. Your text is encrypted on your device.
2. Ente stores only ciphertext.
3. The decryption key stays in the URL fragment (`#...`) and is not sent to
   Ente's servers.
4. The link can be opened once.

After a successful open, the paste is deleted. If it is never opened, it
expires after 24 hours.

## Limits

- Maximum text length: 5000 characters.
- Anonymous usage: no Ente account required to create or open a paste.
- One-time access: opening the link consumes it.

## Notes

- Link preview crawlers are ignored so they do not consume your paste.
- If someone opens an already-consumed or expired link, they will see that the
  paste is unavailable.
