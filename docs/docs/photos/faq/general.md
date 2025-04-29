---
title: General FAQ
description: An assortment of frequently asked questions about Ente Photos
---

# General FAQ

## How can I earn free storage?

Use our [referral program](/photos/features/referral-program/).

## What file formats does Ente support?

Ente supports all files that have a mime type of `image/*` or `video/*`
regardless of their specific format.

However, we only have limited support for RAW currently. We are working towards
adding full support, and you can watch this
[thread](https://github.com/ente-io/ente/discussions/625) for updates.

If you find an issue with ente's ability to parse a certain file type, please
write to [support@ente.io](mailto:support@ente.io) with details of the
unsupported file format and we will do our best to help you out.

## Is there a file size limit?

Yes, we currently do not support files larger than 4 GB.

If this constraint is a concern for you, please write to
[support@ente.io](mailto:support@ente.io) with your use case and we will do our
best to help you.

## Does Ente support videos?

Ente supports backing up and downloading of videos in their original format and
quality.

But some of these formats cannot be streamed on the web browser and you will be
prompted to download them.

## Why does Ente consume lesser storage than other providers?

Most storage providers compute your storage quota in GigaBytes (GBs) by dividing
your total bytes uploaded by `1000 x 1000 x 1000`.

Ente on the other hand, computes your storage quota in GibiBytes (GiBs) by
dividing your total bytes uploaded by `1024 x 1024 x 1024`.

We decided to leave out the **i** from **GiBs** to reduce noise on our
interfaces.

## Why should I trust Ente for long-term data-storage?

Unlike large companies, we have a focused mission, to build a safe space where
you can easily archive your personal memories.

This is the only thing we want to do, and with our pricing model, we can
profitably do it.

We preserve your data end-to-end encrypted, and our open source apps have been
[externally audited](https://ente.io/blog/cryptography-audit/).

Also, we have spent great deal of engineering effort into designing reliable
data replication and graceful disaster recovery plans. This is also done
transparently - we have documented the specifics of our replication and
reliability [here](https://ente.io/reliability).

In short, we love what we do, we have no reasons to be distracted, and we are as
reliable as any one can be.

If you would like to fund the development of this project, please consider
[subscribing](https://ente.io/download).

## How do I pronounce ente?

It's like cafe 😊. kaf-_ay_. en-_tay_.

## Does Ente apply compression to uploaded photos?

Ente does not apply compression to uploaded photos. The file size of your photos
in Ente will be similar to the original file sizes you have.

## Can I add photos from a shared album to albums that I created in Ente?

On Ente's mobile apps, you can add photos from an album that's shared with you,
into one of your own albums. This will create a copy of the item that you fully
own, and will count against your storage quota.

## Can I sync a folder containing multiple subfolders, each representing an album?

Yes, when you drag and drop the folder onto the desktop app, the app will detect
the multiple folders and prompt you to choose whether you want to create a
single album or separate albums for each folder.

## How do I keep NAS and Ente photos synced?

Please try using our CLI to pull data into your NAS
https://github.com/ente-io/ente/tree/main/cli#readme.

## Is there a way to view all albums on the map view?

Currently, the Ente mobile app allows you to see a map view of all the albums by
clicking on "Your map" under "Locations" on the search screen.

## How to reset my password if I lost it?

On the login page, enter your email and click on Forgot Password. Then, enter your recovery key and create a new password.

 # iOS Album Backup and Organization in Ente

 ### How does Ente handle photos that are part of multiple iOS albums?
When you select multiple albums for backup, Ente prioritizes uploading each photo to the album with the fewest photos. This means a photo will only be uploaded once, even if it exists in multiple albums on your device. If you create new albums on your device after the initial backup, those photos may not appear in the corresponding Ente album if they were already uploaded to a different album.


### Why don’t all photos from a new iOS album appear in the corresponding Ente album?
If you create a new album on your device after the initial backup, the photos in that album may have already been uploaded to another album in Ente. To fix this, go to the "On Device" album in Ente, select all photos, and manually add them to the corresponding album in Ente.

### What happens if I reorganize my photos in the iOS Photos app after backing up?
Reorganizing photos in the iOS Photos app (e.g., moving photos to new albums) won’t automatically reflect in Ente. You’ll need to manually add those photos to the corresponding albums in Ente to maintain consistency.

### Can I search for photos using the descriptions I’ve added?
Yes, descriptions are searchable, making it easier to find specific photos later.
To do this, open the photo, tap the (i) button, and enter your description.

### How does the deduplication feature work on the desktop app?
If the app finds exact duplicates, it will show them in the deduplication. When you delete a duplicate, the app keeps one copy and creates a symlink for the other duplicate. This helps save storage space.

### What happens if I lose access to my email address? Can I use my recovery key to bypass email verification?
No, the recovery key does not bypass email verification. For security reasons, we do not disable or bypass email verification unless the account owner reaches out to us and successfully verifies their identity by providing details about their account.

If you lose access to your email, please contact our support team at
support@ente.io
