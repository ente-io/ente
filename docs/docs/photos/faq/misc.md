---
title: Miscellaneous general FAQ
description: Unsorted frequently asked questions about Ente Photos
---

# Miscellaneous FAQ

## Exif Description

Ente will try to read as much information from Exif when the image is uploaded,
but after that, only the fields which have been parsed into Ente can be
searched.

The app still show all the fields in the raw Exif data in the file info panel
when someone taps on the "View all Exif" option, but otherwise the app is
unaware of these fields.

In particular, for the description associated with a photo, the exact logic to
determine the description from the Exif when uploading the image can be seen
[in this part of the code](https://github.com/ente-io/ente/blob/0dcb185744da469848b41b668fe4b647226b6fe2/web/packages/gallery/services/exif.ts#L609-L620).
