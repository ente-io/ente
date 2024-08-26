---
title: Photo dates
description: Handling of metadata, in particular creation dates, in Ente Photos
---

# Photos dates

This document describes Ente's handling of metadata, in particular photo
creation dates.

## Import

Ente will import the date for your photos from three places:

1. Exif
2. Metadata JSON
3. File name

### Exif

Normally, Ente app tries to read the date of the photo from the Exif and other
metadata (e.g. XMP, IPTC) embedded in the file.

> [!TIP]
>
> You can see all of the Exif metadata embedded within a photo by using the
> "View all Exif data" option in the info panel for the photo in Ente.

### Importing from Google takeout

In case of photos exported from Google Photos, the metadata is not embedded
within the file itself, but is instead present in a separate sidecar ".json"
file. Ente knows how to read these files, and in such cases can pick up the
metadata from them.

When you export your data using a Google takeout, Google provides you both your
photos and their associated metadata JSON files. However, for incomprehensible
reasons, they split the JSON and photo across zip files. That is, in some cases
if you have a file named `flower.jpeg`, which has an associated metadata JSON
file named `flower.json`, Google will put the `.jpeg` and the `.json` in
separate takeout zips, and Ente will be unable to correlate them.

To avoid such issues, **we [recommend](/photos/migration/from-google-photos/)
unzipping all of your Google takeout zips into a single folder, and then
importing that folder into Ente**. This way, we will be able to always correctly
map, for example, `flower.jpeg` and `flower.json` and show the same date for
`flower.jpeg` that you would've seen within Google Photos.

### Screenshots

In case the photo does not have a date in the Exif data (and it is not a Google
takeout), for example, for screenshots or Whatsapp forwards, Ente will still try
and deduce the correct date for the file from the name of the file.

> [!NOTE]
>
> This process works great most of the time, but it is inherently based on
> heuristics and is not exact.

## Export

Ente guarantees that you will get back the _exact_ same original photos and
videos that you imported. The modifications (e.g. date changes) you make within
Ente will be written into a separate metadata JSON file during export so as to
not modify the original.

> There is one exception to this. For JPEG files, the Exif DateTimeOriginal is
> changed during export from web or desktop apps. This was done on a customer
> request, but in hindsight this has been an incorrect move. We are going to
> deprecate this behavior, and will instead provide separate tools (or
> functionality within the app itself) for customers who intentionally wish to
> modify their originals to reflect the associated metadata JSON.

### File creation time.

The photo's data will be preserved verbatim, however when it is written out to
disk on a new machine a new file gets created. This file will not have the same
file system creation time as the file that was uploaded.

1. "Creation time" is not a universal concept, e.g. Linux does not support it.
   From the man page of [fstat](https://linux.die.net/man/2/fstat), we can see
   that this information is just not recorded by the file system on Linux.

2. The isn't a way to set it even on Windows and macOS for files downloaded from
   the browser, or for files saved from the mobile apps.

We have considered modifying our desktop and CLI clients to write back the
photo's creation time into the creation time of the filesytem file during
export. But it is not clear if this would be less or more confusing. There are
two main downsides:

1. It will be inconsistent. This behaviour would only happen on Windows and
   macOS, and only when using the desktop or CLI, not for other Ente clients.
   Learning from our experience of modifying DateTimeOriginal, we feel
   consistency is important.

2. It will require workarounds. e.g. for the desktop app, Node.js doesn't
   natively support modifying the creation time (for similar reasons as
   described above), and we will have to include binary packages like
   [utimes](https://github.com/baileyherbert/utimes).

We will also note that Ente is a photos app, not a file system backup app. The
customers for whom the creation time of the file on disk is paramount might be
better served by file backup apps, not a photos app.

All this said though, nothing is set in stone. If enough customers deem it
important, we will prioritize adding support for the workaround.
