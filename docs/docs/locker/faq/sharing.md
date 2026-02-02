---
title: Sharing FAQ
description: Frequently asked questions about sharing in Ente Locker
---

# Sharing FAQ

Answers to common questions about sharing documents and collections in Ente
Locker.

## Sharing with Users

### How do I share my emergency contacts with family? {#locker-share-family}

1. Create a collection for emergency contacts (or use an existing one)
2. Add all relevant emergency contacts to the collection
3. Open the collection and tap the share button
4. Select **Share with Ente user**
5. Enter your family member's Ente email address
6. Choose permissions (Viewer or Collaborator)
7. Tap **Share**

Your family member will receive the shared collection in their Locker app.

### Can I share with non-Ente users? {#locker-share-non-users}

Yes, using public links. Create a public link that can be opened in any
web browser:

1. Open the document or collection
2. Tap the share button
3. Select **Create public link**
4. Copy and share the link

Learn more about [Public links](/locker/features/sharing/public-links).

### What happens when I update a shared document? {#locker-update-shared}

When you update a document shared with Ente users:

- Changes sync automatically to all recipients
- They see the updated content next time they open it
- No notification is sent for updates

For public links, viewers see the current version when they access the
link.

### What happens if I revoke access to shared content? {#locker-revoke-access}

When you remove someone's access:

- They immediately lose the ability to view the content
- The content disappears from their Locker
- Any public links are unaffected (must be revoked separately)

### Can viewers add items to shared content? {#locker-viewer-edit}

No. Viewers can only view content. To allow adding items, share with
Collaborator permissions instead.

### Can I see who has access to my shared content? {#locker-access-tracking}

Yes. Open the shared document or collection, tap the share button, and
view the list of people with access.

## Public Links

### Are public links end-to-end encrypted? {#locker-public-link-encryption}

Yes and no. The content remains encrypted on Ente's servers. However, the
decryption key is embedded in the URL, so anyone with the link can
decrypt and view the content.

For sensitive information, use password protection on public links.

### Can I see who viewed my public link? {#locker-link-analytics}

No. Ente does not track who views public links to maintain privacy.
We can tell you how many devices have accessed a link, but not who.

### What happens if I share a sensitive password via public link? {#locker-sensitive-public}

Anyone with the link can view the password. For sensitive content:

1. Add a password to the link
2. Set an expiration date
3. Share the link password through a separate channel
4. Revoke the link after use

### Can I set a public link to expire? {#locker-link-expiry}

Yes. When creating or editing a public link:

1. Tap **Set expiration**
2. Choose when the link should expire
3. After expiration, the link stops working

### How do I revoke a public link? {#locker-revoke-link}

1. Open the shared document or collection
2. Tap the share button
3. Find the public link you want to revoke
4. Tap it and select **Delete link**

The link immediately stops working.

## Security

### How does sharing work with encryption? {#locker-sharing-encryption}

When sharing with Ente users:

1. Your device encrypts the sharing key with the recipient's public key
2. Only their device can decrypt this key
3. Ente's servers never have access to the decrypted content

For public links:

1. The decryption key is added to the URL fragment
2. The fragment is never sent to servers
3. Anyone with the full URL can decrypt the content

### Is it safe to share passwords via Locker? {#locker-safe-password-sharing}

When sharing with Ente users, yes. The end-to-end encryption protects
the content.

When using public links, be cautious:

- Add a password to the link
- Set an expiration date
- Share the link through secure channels
- Revoke after use

## Related Features

- [Share with users](/locker/features/sharing/share-with-users)
- [Public links](/locker/features/sharing/public-links)
- [Encryption](/locker/features/security/encryption)
