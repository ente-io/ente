---
title: Migration FAQ
description: Frequently asked questions about migrating to Ente Photos from other services
---

# Migration

## Importing from Google Photos

### How much Ente storage do I need when importing my Google Photos Takeout? {#google-takeout-storage}

When importing your Google Photos Takeout into Ente, your storage usage is based on your actual Google Photos library size — not the (much larger) Takeout ZIP size.

For example, if Google Photos reports 30 GB used, but your Takeout export is 100 GB, you will need around 30 GB of Ente storage.

Google includes duplicate copies of the same photos inside multiple album folders in the Takeout export. Ente detects these during import and only stores a single original.

If any duplicates slip through and you temporarily hit your storage limit, you can clean them up using the desktop app's built-in deduplication tool:

`Desktop app → Settings → Deduplicate files`

This removes exact duplicates while keeping one original safely.

### How does Ente handle Google Takeout metadata? {#google-takeout-metadata}

When you export your data using Google Takeout, Google provides both your photos and their associated metadata JSON files. However, Google sometimes splits the JSON and photo across different zip files.

For example, `flower.jpeg` might be in one zip and `flower.json` in another. This prevents Ente from correctly mapping them.

**Best practice**: We [recommend](/photos/migration/from-google-photos/)
unzipping all of your Google Takeout zips into a single parent folder, keeping
subfolders as-is (do not flatten files), then importing that parent folder into
Ente. This way, we can always correctly map photos and their metadata.

### Why are my Google Photos dates wrong after import? {#google-photos-dates-wrong}

If the dates appear incorrect after importing from Google Takeout, it's usually because:

- The photo's Exif data has a different date than Google's metadata JSON
- The JSON file wasn't matched with the photo during import

To fix this:

1. Make sure you unzipped all Google Takeout zips into one parent folder (with
   subfolders kept as-is)
2. Import that parent folder (not individual zips)
3. This ensures Ente can match JSON files with their photos

### Can I retry failed uploads?

Yes. You can check the progress/info tab that appears during upload to determine the cause of failed uploads. You can also drag and drop the folder or files again. Ente will automatically ignore already backed up files and try to upload just the rest.

### Why does my google takeout upload fail?

This usually occurs due to a network connectivity issue:

- Check your internet connection is active
- Try switching networks (WiFi to mobile data or vice versa)
- If using VPN, try disabling it temporarily
- Check if your firewall is blocking Ente's servers
- On desktop/web, try disabling "Faster uploads" in Settings > Preferences > Advanced

For more check: [Troubleshooting](https://ente.io/help/photos/faq/troubleshooting#desktop-app-issues)

### How do I prevent duplicates while migrating from Google Photos? {#prevent-duplicates-migration}

Ente detects duplicates by identical hash, file name and creation time.

Duplicates can occur:

1. **If editing is done in Google Photos.**
   The original photo as well as edited copies are saved and exported separately in Google Takeout. They have different hash values and are thus not detected as duplicates by Ente.

2. **If storage saver mode is enabled or compressed photos are stored in Google Photos.**
   If the same photos are present locally in phone in original quality and are also backed up to Ente along with Google Takeout, Ente does not recognize these as duplicates due to different hash values.

3. **If upload from Google Takeout on desktop and backup from mobile folders run simultaneously.**
   When the same photos come in from two different sources at the same time, Ente may not detect they are duplicates and both copies may be uploaded.

**Steps to prevent duplication due to the above reasons:**

1. All required photo folders from mobile are backed up to Google Photos.
2. Disable backup in Google Photos.
3. Request Google Takeout.
4. Empty any local photo folders which are part of Google Takeout and also need to be backed up post migration.
   - External tools can be used to deduplicate Google Takeout before importing into Ente.
5. Import Google Takeout using Ente desktop app.
6. After successful import, enable desired photo folder backup on Ente mobile app.

**If duplicates still arise after migration and upload:**

- Use the [Remove duplicates](/photos/features/albums-and-organization/storage-optimization#remove-exact-duplicates) option.
- Use the [Remove similar images](/photos/features/albums-and-organization/storage-optimization#remove-similar-images) option. (Ensure Machine Learning is enabled in Settings for similar-image detection)

> [!NOTE]
>
> Special mention to l1br3770 for his [detailed guide](https://www.reddit.com/r/enteio/comments/1jyxk4b/howto_migration_from_google_photos_pitfalls/).
### Can I reupload the Google Takeout in case I did not upload it correctly the first time?

Yes, you can start fresh.

- Open home gallery view and press Ctrl + A to select everything, then delete all items.
- After that, open Trash. It may take a little while for all deleted items to sync into Trash.
- Once synced, empty Trash to permanently remove all items from your account.

Once this is done, you can reupload your entire Google Takeout folder again using the desktop app.
### Is there a way to remove partner sharing photos when importing via Google Takeout?

There is currently no built-in filter to automatically remove partner-shared photos when importing from Google Takeout.

## Importing from Apple Photos

### Why is it recommended to migrate Apple Photos from mobile? {#why-migrate-apple-photos-from-mobile}

It is highly recommended to import from Apple Photos via mobile rather than desktop, as mobile upload preserves metadata, while desktop upload may lose metadata (reason stated [below](#can-i-import-apple-photos-via-desktop)), requires manual export and sequential naming for live photos.

### Can I import Apple Photos via desktop? {#can-i-import-apple-photos-via-desktop}

It is highly recommended to import from Apple Photos via mobile rather than desktop.

Some photos may not have EXIF metadata embedded directly within the image file. In these cases, Apple Photos exports metadata into separate `.XMP` sidecar files instead of writing it into the photo itself.

Currently, the desktop app does not read metadata from separate XMP sidecar files — it can only recognize metadata that is embedded within the file.

We recommend to upload the photos using the iPhone app as iOS exports typically include embedded metadata, which ensures dates and other details are preserved correctly.

However, for any reason, if desktop is the only way to import, you can follow the steps below:

#### 1. Export your data from the Apple Photos app.

Select the files you want to export (`Command + A` to select them all), and
click on `File` > `Export` > `Export Unmodified Originals`.

In the dialog that pops up, select File Name as `Sequential` and provide any
prefix you'd like. This is to make sure that we combine the photo and video
portions of your Live Photos correctly.

Finally, choose an export directory and confirm by clicking `Export Originals`.
You will receive a notification from the app once your export is complete.

#### 2. Import into Ente

Now simply drag and drop the downloaded folders into
[our desktop app](https://ente.io/download/desktop) and grab a cup of coffee (or
a good night's sleep, depending on the size of your library) while we handle the
rest.

> Note: In case your uploads get interrupted, just drag and drop the folders
> into the same albums again, and we will ignore already backed up files and
> upload just the rest.
