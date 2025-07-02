---
title: Metadata
description: Handling of metadata in Ente Photos
---

# Metadata

This document describes Ente's handling of metadata

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

### File name

In case the photo does not have a date in the Exif data (and it is not a Google
takeout), for example, for screenshots or Whatsapp forwards, Ente will still try
and deduce the correct date for the file from the name of the file.

> [!NOTE]
>
> This process works great most of the time, but it is inherently based on
> heuristics and is not exact.

If we are unable to decipher the creation time from these 3 sources, we will set
the upload time as the photo's creation time.

## Modifications

Ente supports modifications to the following metadata:

- File name
- Date & time
- Location

The first two options are available on both mobile and desktop, while the
ability to update location is only available within our mobile apps.

### Bulk modifications

You can bulk-edit creation time of photos from our desktop app, by
multi-selecting items and selecting the "Fix time" option from the action bar.

You can bulk-edit location coordinates of photos from our mobile app, by
multi-selecting items and selecting the "Edit location" option from the action
bar.

## Export

Ente guarantees that you will get back the _exact_ same original photos and
videos that you imported. The modifications (e.g. date changes) you make within
Ente will be written into a separate metadata JSON file during export so as to
not modify the original.

As an example: suppose you have `flower.png`. When you export your library, you
will end up with:

```
flower.png
metadata/flower.png.json
```

Ente writes this JSON in the same format as Google Takeout so that if a tool
supports Google Takeout import, it should be able to read the JSON written by
Ente too.

> One small difference is that, to avoid clutter, Ente puts the JSON in the
> `metadata/` subfolder, while Google puts it next to the file.<br>
>
> <br>Ente itself will read it from either place.

Here is a sample of how the JSON would look:

```json
{
    "description": "This will be imported as the caption",
    "creationTime": {
        "timestamp": "1613532136",
        "formatted": "17 Feb 2021, 03:22:16 UTC"
    },
    "modificationTime": {
        "timestamp": "1640225957",
        "formatted": "23 Dec 2021, 02:19:17 UTC"
    },
    "geoData": {
        "latitude": 12.004170700000001,
        "longitude": 79.8013945
    }
}
```

`photoTakenTime` will be considered as an alias for `creationTime`, and
`geoDataExif` will be considered as a fallback for `geoData`.

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
