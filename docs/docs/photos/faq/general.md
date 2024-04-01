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

Ente does not apply compression to uploaded photos. The file size of your photos in Ente will be similar to the original file sizes you have.

## Can I add photos from a shared album to albums that I created in Ente?

Currently, Ente does not support adding photos from a shared album to your personal albums. If you want to include photos from a shared album in your own albums, you will need to ask the owner of the photos to add them to your album. 

## How do I ensure that the Ente desktop app stays up to date on my system?

Ente desktop includes an auto-update feature, ensuring that whenever updates are deployed, the app will automatically download and install them. You don't need to manually update the software.

## Can I sync a folder containing multiple subfolders, each representing an album?

Yes, when you drag and drop the folder onto the desktop app, the app will detect the multiple folders and prompt you to choose whether you want to create a single album or separate albums for each folder.

## What is the difference between **Magic** and **Content** search results on the desktop?

**Magic** is where you can search for long queries. Like, "baby in red dress", or "dog playing at the beach".

**Content** is where you can search for single-words. Like, "car" or "pizza".

## How do I identify which files experienced upload issues within the desktop app?

Check the sections within the upload progress bar for "Failed Uploads," "Ignored Uploads," and "Unsuccessful Uploads."