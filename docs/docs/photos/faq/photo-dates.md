---
title: Photo dates
description: Ensuring correct metadata and dates in Ente Photos
---

# Photos dates

Ente will import the date for your photos from three places:

1. Exif
2. Metadata JSON
3. File name

## Exif

Normally, Ente app tries to read the date of the photo from the Exif and other
metadata (e.g. XMP, IPTC) embedded in the file.

> [!TIP]
>
> You can see all of the Exif metadata embedded within a photo by using the
> "View all Exif data" option in the info panel for the photo in Ente.

## Importing from Google Takeout

In case of photos exported from Google Photos, the metadata is not embedded
within the file itself, but is instead present in a separate sidecar ".json"
file. Ente knows how to read these files, and in such cases can pick up the
metadata from them.

When you export your data using a Google Takeout, Google provides you both your
photos and their associated metadata JSON files. However, for incomprehensible
reasons, they split the JSON and photo across zip files. That is, in some cases
if you have a file named `flower.jpeg`, which has an associated metadata JSON
file named `flower.json`, Google will put the `.jpeg` and the `.json` in
separate Takeout zips, and Ente will be unable to correlate them.

To avoid such issues, **we [recommend](/photos/migration/from-google-photos/)
unzipping all of your Google takeout zips into a single folder, and then
importing that folder into Ente**. This way, we will be able to always correctly
map, for example, `flower.jpeg` and `flower.json` and show the same date for
`flower.jpeg` that you would've seen within Google Photos.

## Screenshots

In case the photo does not have a date in the Exif data (and it is not a Google
Takeout), for example, for screenshots or Whatsapp forwards, Ente will still try
and deduce the correct date for the file from the name of the file.

> [!NOTE]
>
> This process works great most of the time, but it is inherently based on
> heuristics and is not exact.
