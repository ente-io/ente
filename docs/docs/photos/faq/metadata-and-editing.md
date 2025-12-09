---
title: Metadata and Editing FAQ
description: Frequently asked questions about photo metadata, EXIF data, and editing in Ente Photos
---

# Metadata and Editing

## Viewing Metadata

### What metadata does Ente preserve during import? {#metadata-preserved}

Ente reads and preserves:

- **EXIF data**: Camera settings, date taken, GPS coordinates
- **XMP and IPTC**: Additional metadata standards
- **Google Takeout JSON**: If importing from Google Photos
- **Filename-based dates**: For files without EXIF (like screenshots)

All this metadata is:

- Encrypted before upload
- Preserved when you export

### How does Ente handle Exif data and descriptions? {#exif-handling}

Ente will try to read as much information from Exif metadata when the image is uploaded, but after that, only the fields which have been parsed into Ente can be searched.

The app still shows all the fields in the raw Exif data in the file info panel when someone taps on the "View all Exif" option, but otherwise the app is unaware of these fields.

In particular, for the description associated with a photo, the exact logic to determine the description from the Exif when uploading the image can be seen [in this part of the code](https://github.com/ente-io/ente/blob/0dcb185744da469848b41b668fe4b647226b6fe2/web/packages/gallery/services/exif.ts#L609-L620).

### Where does Ente import photo dates from? {#photo-date-sources}

Ente will import the date for your photos from three places (in order of priority):

1. **EXIF data**: Normally, Ente tries to read the date from the Exif and other metadata (e.g. XMP, IPTC) embedded in the file.

2. **Metadata JSON** (Google Takeout): In case of photos exported from Google Photos, the metadata is not embedded within the file itself, but is instead present in a separate sidecar ".json" file. Ente knows how to read these files.

3. **File name**: If the photo does not have a date in the Exif data (and it is not a Google takeout), for example, for screenshots or WhatsApp forwards, Ente will try and deduce the correct date for the file from the name of the file.

> **Note**: The filename-based detection works great most of the time, but it is inherently based on heuristics and is not exact.

If we are unable to decipher the creation time from these 3 sources, we will set the upload time as the photo's creation time.

### How do I view EXIF data for a photo? {#view-exif}

**On mobile and web:**

1. Open the photo
2. Tap/click the info button (i)
3. Scroll down to see basic metadata
4. Tap "View all Exif data" to see complete EXIF information

This shows all the technical data about the photo including camera settings, lens information, and more.

## Importing from Google Photos

### How does Ente handle Google Takeout metadata? {#google-takeout-metadata}

When you export your data using Google Takeout, Google provides both your photos and their associated metadata JSON files. However, Google sometimes splits the JSON and photo across different zip files.

For example, `flower.jpeg` might be in one zip and `flower.json` in another. This prevents Ente from correctly mapping them.

**Best practice**: We [recommend](/photos/migration/from-google-photos/) unzipping all of your Google Takeout zips into a single folder, then importing that folder into Ente. This way, we can always correctly map photos and their metadata.

### Why are my Google Photos dates wrong after import? {#google-photos-dates-wrong}

If the dates appear incorrect after importing from Google Takeout, it's usually because:

- The photo's Exif data has a different date than Google's metadata JSON
- The JSON file wasn't matched with the photo during import

To fix this:

1. Make sure you unzipped all Google Takeout zips into one folder
2. Import that single folder (not individual zips)
3. This ensures Ente can match JSON files with their photos

## Editing Metadata

### How do I add descriptions or captions to photos? {#add-descriptions}

You can add descriptions (captions) to your photos in Ente:

**On mobile and web:**

1. Open the photo
2. Tap/click the info button (i)
3. Tap/click "Add description" or the description field
4. Type your description
5. Save

**Searchability**: Descriptions are searchable! You can find photos later by searching for words in their descriptions.

**Privacy**: Like all your data in Ente, descriptions are stored end-to-end encrypted.

### Can I bulk edit photo dates? {#bulk-edit-dates}

Yes! You can bulk-edit creation time of photos from the desktop app:

1. Multi-select the photos you want to edit (Ctrl/Cmd+click or Shift+click)
2. Select the "Fix time" option from the action bar
3. Choose the correct date/time
4. Apply to all selected photos

This is useful for:

- Fixing photos with incorrect timestamps
- Adjusting timezone differences
- Correcting dates on scanned photos

**Note**: This feature is currently only available on the desktop app.

### Can I bulk edit photo locations? {#bulk-edit-locations}

Yes! You can bulk-edit location coordinates from the mobile app:

1. Long press to multi-select the photos you want to edit
2. Select "Edit location" from the action bar
3. Choose the correct location on the map
4. Apply to all selected photos

This is useful for:

- Adding location to photos without GPS data
- Correcting wrong GPS coordinates
- Organizing photos by location after the fact

**Note**: This feature is currently only available on the mobile app.

### How do I fix incorrect photo dates? {#fix-incorrect-dates}

Photos sometimes have incorrect dates due to:

- Camera settings being wrong
- Timezone issues
- Scanned photos without proper metadata

**To fix dates:**

1. Use the bulk date editing feature (see above)
2. Select photos with incorrect dates
3. Apply the correct date/time

Ente will store your corrections and sync them across all your devices.

### Are my metadata edits reversible? {#edits-reversible}

Yes! When you edit metadata (dates, locations, descriptions) in Ente, the **original file is never modified**. Your edits are stored separately.

When you export your photos:

- You get the exact original file
- Edits are saved in a separate JSON file (same format as Google Takeout)
- This preserves both the original and your modifications

This means:

- You can always access the original metadata
- Your edits are preserved when exporting
- Your original files remain untouched

### How do I edit photo filenames? {#edit-filenames}

You can rename photos in Ente:

**On mobile and web:**

1. Open the photo
2. Tap/click the info button (i)
3. Tap/click on the filename
4. Enter the new name
5. Save

The original filename is preserved, and your edit is stored separately (similar to other metadata edits).

### Can I add location data to photos that don't have it? {#add-location}

Yes! You can manually add location data to any photo:

**On mobile:**

1. Select the photo(s)
2. Choose "Edit location" from the menu
3. Select the location on the map
4. Save

This adds GPS coordinates to the photo's metadata, allowing you to:

- View them on the map
- Search by location
- Organize photos by where they were taken

See [Bulk edit photo locations](#can-i-bulk-edit-photo-locations) for editing multiple photos at once.

## Exporting Metadata

### Does the exported data preserve metadata? {#export-data-preserve-metadata}

Yes, the metadata is written out to a separate JSON file during export. Note that the original is not modified.

When you export your library, suppose you have `flower.png`. You will end up with:

```
flower.png
metadata/flower.png.json
```

Ente writes this JSON in the same format as Google Takeout so that if a tool supports Google Takeout import, it should be able to read the JSON written by Ente too.

> One small difference: to avoid clutter, Ente puts the JSON in the `metadata/` subfolder, while Google puts it next to the file. Ente itself will read it from either place.

Here is a sample of how the JSON looks:

```json
{
    "description": "This will be imported as the caption",
    "photoTakenTime": {
        "timestamp": "1613532136",
        "formatted": "17 Feb 2021, 03:22:16 UTC"
    },
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

Ente writes both timestamp blocks: `photoTakenTime` holds the photo's capture time (the value other apps and Takeout expect), while `creationTime` is kept only for backward compatibility with older exports that relied on it and may be dropped in a future version. When importing, Ente treats `photoTakenTime` as canonical and falls back to `creationTime` if needed. `geoDataExif` will be considered as a fallback for `geoData`.

> [!NOTE]
>
> The `creationTime` field is deprecated and will be removed in a future release. Prefer `photoTakenTime`.

### What happens to file creation time during export? {#file-creation-time}

The photo's data will be preserved verbatim, however when it is written out to disk on a new machine a new file gets created. This file will not have the same file system creation time as the file that was uploaded.

There are two reasons for this:

1. **"Creation time" is not universal**: For example, Linux does not support it. From the man page of [fstat](https://linux.die.net/man/2/fstat), we can see that this information is just not recorded by the file system on Linux.

2. **Cannot be set from browsers or mobile apps**: There isn't a way to set it even on Windows and macOS for files downloaded from the browser, or for files saved from the mobile apps.

We have considered modifying our desktop and CLI clients to write back the photo's creation time into the creation time of the filesystem file during export. But it is not clear if this would be less or more confusing due to inconsistencies across platforms.

Ente is a photos app, not a file system backup app. Customers for whom the creation time of the file on disk is paramount might be better served by file backup apps.

### Can I modify the original files during export? {#modify-originals}

No. Ente guarantees that you will get back the _exact_ same original photos and videos that you imported. The modifications (e.g. date changes) you make within Ente will be written into a separate metadata JSON file during export so as to not modify the original.

This ensures:

- You always have access to originals
- Your edits are preserved separately
- You can use the metadata JSON with other tools

## Platform-Specific Behavior

### Do metadata edits sync across devices? {#edits-sync}

Yes! All metadata edits (dates, locations, descriptions, filenames) are synced across all your devices using end-to-end encryption.

When you edit metadata on one device:

- Changes appear on all other devices
- The original file remains unchanged everywhere
- Edits are preserved when exporting from any device

### Can I edit metadata on all platforms? {#platform-support}

**Available on mobile and desktop:**

- Adding descriptions
- Editing filenames
- Viewing all EXIF data

**Desktop only:**

- Bulk editing dates ("Fix time" feature)

**Mobile only:**

- Bulk editing locations

We're working on bringing all editing features to all platforms.

### Does Ente modify any file metadata? {#modify-file-metadata}

No. Ente never modifies your original files or their embedded metadata. All edits you make are stored separately in Ente's database and:

- Synced encrypted across your devices
- Written to separate JSON files during export
- Kept separate from the original file

Your original photos with their original metadata remain untouched.
