---
title: Share
description: Securely share photos and videos stored in Ente Photos
---

# Sharing

Ente supports end-to-end encrypted sharing of your photos and videos.

This allows you to share your photos and videos with only the people you want,
without them being visible to anybody else. The files remain encrypted at all
times, and only the people you have shared with get the decryption keys.

- If the person you want to share with is already on Ente, you can share an
  album with them by entering their email address.

- If they are not already on Ente, you can send them an invite and then share
  with them after they've signed up.

- Alternatively, you can create public links to share albums with people who are
  not on Ente.

With public links, the files are still end-to-end encrypted, so the sharing is
still secure. Note that the decryption keys are part of the public link so keep
in mind that anybody with the link will be able to share it with others.

Both shared albums and public links allow [collaboration](collaborate).

## Links

You can create links to your albums by opening an album and clicking on the
Share icon. They are publicly accessible by anyone who you share the link with.
They don't need an app or account.

These links can be password protected, or set to expire after a while.

You can read more about the features supported by Links
[here](https://ente.io/blog/powerful-links/).

## Albums

If your loved ones are already on Ente, you can share an album with their
registered email address.

If they are your partner, you can share your `Camera` folder on Android, or
`Recents` on iOS. Whenever you click new photos, they will automatically be
accessible on your partner's device.

## Collaboration

You can allow other Ente users to add photos to your album. This is a great way
for you to build an album together with someone. You can control access to the
same album - someone can be added as a `Collaborator`, while someone else as a
`Viewer`.

If you wish to collect photos from folks who are not Ente, you can do so with
our Links. Simply tick the box that says "Allow uploads", and anyone who has
access to the link will be able to add photos to your album.

## Organization

You can favorite items that have been shared with you, and organize them into
your own albums.

When you perform these operations, Ente will create a hard copy of these items,
that you fully own. This means, these copied items will count against your
storage space.

We understand there are use cases where this approach will consume extra space
(for eg. if you are organizing photos of a family member). We chose hard copies
as a first version to avoid complexities regarding the ownership of shared
items, in case the original owner were to delete it from their own library.

We plan to tackle these complexities in the future, by copying a reference to
the item that was shared, instead of the actual file, so that your storage will
only get consumed if the original owner deletes it from their library. If this
sounds useful to you, please participate in
[this discussion](https://github.com/ente-io/ente/discussions/790).

## Technical details

More details, including technical aspect about how the sharing features were
implemented, are in various blog posts announcing these features.

- [Collaborative albums](https://ente.io/blog/collaborative-albums)

- [Collect photos from people not on ente](https://ente.io/blog/collect-photos)

- [Shareable links for albums](https://ente.io/blog/shareable-links),
  [and their underlying technical implementation](https://ente.io/blog/building-shareable-links).
  Since then, we have also added the ability to password protect public links,
  and configure a duration after which the link will automatically expire.

We are now working on the other requested features around sharing, including
comments and reactions.

## Limitations

Sharing is only available to paid customers. This limitation safeguards against
potential platform abuse.
