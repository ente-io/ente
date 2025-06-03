---
title: Deduplicate
description: Removing duplicates photos using Ente Photos
---

# Deduplicate

Ente performs two different duplicate detections: one during uploads, and one
that can be manually run afterwards to remove duplicates across albums.

## During uploads

Ente will automatically deduplicate and ignore duplicate files during uploads.

When uploading, Ente will ignore exact duplicate files. This allows you to
resume interrupted uploads, or drag and drop the same folder, or reinstall the
app, and expect Ente to automatically skip duplicates and only add new files.

The duplicate detection works slightly different on each platform, to cater to
the platform's nuances.

#### Mobile

- On iOS, a hash will be used to detect exact duplicates. If the duplicate is
  being uploaded to an album where a photo with the same hash already exists,
  then the duplicate will be skipped. If it is being uploaded to a different
  album, then a symlink will be created (so no actual data will need to be
  uploaded, just a symlink will be created to the existing file).

- On Android also, a hash check is used. But unlike iOS, the native Android
  filesystem behaviour is to keep physical copies if the same photo is in
  different albums. So Ente does the same: duplicates to same album will be
  skipped, duplicates when going to separate albums will create copies.

#### Web and desktop

On laptops (i.e. when using the Ente web or desktop app), in addition to a hash
check, the file name is also used. The assumption is that the user wishes to
keep two copies if they have the same file but with different names.

Thus a file will be considered a duplicate and skipped during upload if a file
with the same name and hash already exists in the album.

And if you're trying to upload it to a different album (i.e. the same file with
the same name already exists in a different album), then a symlink to the
existing file will be created. This is similar to what happens when you do "Add
to album", and the actual files are not re-uploaded.

## Manual deduplication

Ente also provides a tool for manual de-duplication in _Settings → Backup →
Remove duplicates_. This is useful if you have an existing library with
duplicates across different albums, but wish to keep only one copy.

During this operation, Ente will discard duplicates across all albums, retain a
single copy, and add symlinks to this copy within all existing albums. So your
existing album structure remains unchanged, while the space consumed by the
duplicate data is freed up.

## Adding to Ente album creates symlinks

Note that once a file is in Ente, adding it to another Ente album will create a
symlink, so that you can add it to as many albums as you wish but storage will
only be counted once.
