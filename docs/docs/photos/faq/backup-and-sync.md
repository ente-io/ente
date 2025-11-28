---
title: Backup and Sync FAQ
description: Frequently asked questions about backing up and syncing photos in Ente Photos
---

# Backup and Sync

## Mobile Backup

### How does automatic backup work in Ente? {#automatic-backup}

Once you select which albums to backup in your mobile app settings, Ente automatically syncs new photos and videos from those albums to the cloud. Backup happens in the background without needing to open the app.

**Key features:**

- Background sync runs automatically
- Original quality with no compression
- Smart resumption if interrupted
- WiFi-only by default (configurable)

Learn more in the [Backup feature guide](/photos/features/backup-and-sync/).

### How do I select which albums to back up? {#select-albums}

**On mobile:**

Open `Settings > Backup > Backed up folders` and select the albums you want to automatically backup.

Once configured, new photos added to these albums will automatically sync in the background.

### Can I backup over mobile data or only WiFi? {#mobile-data}

By default, Ente only backs up photos over WiFi to save mobile data and battery. However, you can change this setting:

**On mobile:**

Open `Settings > Backup` and toggle "Backup over mobile data".

Note that backing up over mobile data can consume significant data if you have many photos to upload.

### Why is my initial backup taking so long? {#initial-backup-slow}

The initial backup can take time depending on:

- The size of your photo library
- Your internet connection speed
- Whether you're using WiFi or mobile data
- Device battery optimization settings

**Tips to speed up initial backup:**

**On iOS:**

- Keep the app open in foreground for large initial uploads
- Disable automatic screen lock temporarily (`Settings > Backup > Backup settings > Disable auto lock`)
- Videos won't backup in background - keep the app open for them

**On Android:**

- Disable battery optimization for Ente in system settings
- Keep your device connected to power
- Ensure you haven't force-closed the app from recents

**On desktop:**

- Desktop uploads are generally faster than mobile
- Consider doing initial upload from desktop if you have a large library

### What happens if my backup is interrupted? {#backup-interrupted}

If your backup is interrupted (due to network issues, closing the app, or other reasons), Ente will automatically resume from where it left off the next time you have connectivity. You don't need to restart the entire backup process.

### Do deleted photos on my device also delete from Ente? {#deletion-sync}

No. If you delete a photo from your device's native photos app, it will **not** be automatically deleted from Ente. This is by design for two reasons:

1. **Safety**: Prevents accidental loss of photos
2. **Platform restrictions**: iOS and Android don't allow apps to automatically delete photos without manual confirmation

If you want to delete a photo from Ente, you must do it manually within the Ente app.

### Understanding Ente's backup vs. sync paradigm {#backup-vs-sync}

**Ente is a backup service, not a two-way sync service like Google Photos.**

**What this means:**

**Changes in Ente → Your device:**

- ❌ Deleting a photo in Ente does NOT delete it from your device
- ❌ Moving photos between albums in Ente does NOT affect your device albums
- ❌ Renaming albums in Ente does NOT rename device albums

**Changes on your device → Ente:**

- ✅ New photos on your device → automatically backed up to Ente
- ❌ Deleting photos from your device → does NOT delete from Ente
- ❌ Moving photos between device albums → may not update Ente albums
- ❌ Renaming device albums → does NOT rename Ente albums

**Why this design?**

1. **Safety**: Prevents accidental data loss
2. **Platform limitations**: OS restrictions prevent true two-way sync
3. **Backup-first philosophy**: Ente preserves your photos even if you accidentally delete them locally

**What you need to know:**

✅ **Uploading**: Happens automatically for selected albums
✅ **Re-upload protection**: Ente won't re-upload photos you've already uploaded, even if you delete them from Ente and they're still on your device
❌ **Two-way sync**: Not supported - changes in Ente don't reflect on your device

**If you want to delete a photo everywhere:**

1. Delete from Ente app
2. Delete from your device's native Photos app
3. Both deletions must be done manually

### Can I delete photos from my device after backing up to Ente? {#free-up-space-after-backup}

Yes! Once photos are safely backed up to Ente, you can delete them from your device to free up space.

**On mobile:**

Use Ente's "Free up space" feature at `Settings > Backup > Free up space`. Ente will show photos that are backed up and can be safely deleted. Review and confirm deletion.

This feature only deletes photos that have been successfully uploaded to Ente. Photos remain in Ente and can be re-downloaded anytime.

Learn more in the [Storage optimization guide](/photos/features/albums-and-organization/storage-optimization).

### If I delete a photo from Ente, will it be re-uploaded from my device? {#delete-reupload}

**No, it will not be re-uploaded automatically.**

Ente tracks which files have been uploaded and won't upload them again, even if you delete them from Ente while they're still on your device.

**To force a re-upload of previously uploaded files:**

You would need to use "Reset ignored files" in `Settings > Backup`. However, this is rarely needed and should be done carefully as it will re-upload all previously uploaded files.

### How does Ente handle duplicate files during backup? {#duplicate-handling}

Ente automatically detects and handles duplicate files during upload:

- If you try to upload the same photo multiple times to the same album, Ente will skip it
- If you upload the same photo to different albums, Ente creates a symlink (reference) instead of uploading it again
- This saves storage space while maintaining your album structure

This happens automatically in the background without any action required from you.

Learn more in the [Duplicate detection guide](/photos/features/backup-and-sync/duplicate-detection).

### What file formats can I backup? {#backup-file-formats}

Ente supports all files with mime types of `image/*` or `video/*`, regardless of their specific format. This includes:

- Common formats: JPG, PNG, GIF, MP4, MOV, etc.
- Live Photos (both photo and video components)
- RAW formats (limited support currently)

**Limitations:**

- Maximum file size: 10 GB
- Some video formats cannot be streamed on web browsers and must be downloaded

### Does Ente compress my photos during backup? {#does-ente-compress}

No. Ente backs up your photos in **original quality with no compression**. The file size of your photos in Ente will be the same as the original file sizes.

Your photos are encrypted before upload, but encryption doesn't change the quality or apply any compression.

### How can I check my backup status? {#check-backup-status}

**On mobile:**

Open `Settings > Backup > Backup status` to see:

- Number of files backed up
- Files pending upload
- Any errors or issues

**On desktop:**

- Check the sync status indicator in the bottom right corner
- Click to expand and see detailed progress

### How does Ente handle media when Optimize iPhone Storage is enabled? {#optimize-iphone-storage}

When Optimize iPhone Storage is enabled, iOS keeps lower-resolution previews on your device. Ente displays those previews during on-device viewing.

However, for backup, Ente always retrieves the original, full-resolution photo or video directly from iCloud. The same full-resolution files will be available when you download them from Ente.

### Does Ente backup Live Photos from iPhone? {#live-photos-backup}

Yes! Ente fully supports Live Photos from iPhone.

**What gets backed up:**

- The still image (HEIC, JPEG, etc.)
- The video clip (MOV, MP4, etc.)
- Both components in their original quality with no compression

**How it works:**

When you back up a Live Photo, Ente automatically detects it by analyzing the file name, file path, and creation date (both components must be created within a day of each other). Once detected, Ente packages both the image and video components together into a single encrypted ZIP file. This keeps the two parts linked together.

Ente uses a special hash (unique identifier) that combines both components, ensuring they remain associated with each other. This means when you download or view your Live Photo later, both parts are always retrieved together.

Because they're stored as one file, you won't see them as separate items in your library - they appear as a single Live Photo, just like on your iPhone.

**How to view:**

- **On mobile**: Long-press a Live Photo to play the video
- **On web**: Hover over a Live Photo to see it animate
- **On desktop**: Hover over a Live Photo to play it

**Sharing Live Photos:**

Live Photos behave differently depending on how you share them:

- **Using "Send link"**: The recipient gets the full Live Photo with both image and video components
- **Using the "Share" option**: Only the still image is shared
- **Using "Download"**: Downloads the complete Live Photo (image + video)
- **Using "Share" button to save/download**: Only saves the still image

### Does Ente backup Burst photos? {#burst-photos-backup}

Ente backs up a single primary full-resolution image from the Burst. Additional frames from the Burst sequence are not backed up unless each frame is selected and uploaded.

### Why do I see duplicate files in the iOS app when the same photo is in an iCloud Shared Album? {#icloud-shared-album-duplicates}

iCloud Shared Albums store compressed copies, not the original files. Because of this, Ente sees the shared-album copy as a different file, so it gets backed up separately and appears as a duplicate.

## Background Sync

### How does background sync work? {#how-background-sync-works}

Background sync allows Ente to automatically back up your photos without needing to keep the app open. Once you've selected which albums to back up, Ente will monitor those albums and upload new photos in the background.

**On mobile:**

- Works on both iOS and Android
- Backs up photos over WiFi by default (configurable in settings)
- Continues even when the app is closed

**On desktop:**

- Use [watch folders](/photos/faq/backup-and-sync#what-are-watch-folders) to automatically sync specific directories

**Important**: On iOS, large videos may not upload in background - they'll sync when you open the app.

Learn more in the [Background sync feature guide](/photos/features/backup-and-sync/#background-sync).

### Why isn't background sync working on my phone? {#background-sync-not-working}

If photos aren't automatically backing up in the background, try these solutions:

**On Android:**

1. Open device `Settings > Apps > Ente > Battery`
2. Choose "Unrestricted" or disable "Optimize battery usage"
3. Grant all required permissions (Photos, Storage)
4. Ensure you haven't force-closed the app from recents

**On iOS:**

1. Open device `Settings > Ente`
2. Enable "Background App Refresh"
3. Grant "Full Access" to Photos
4. Don't force-quit the Ente app from the app switcher
5. For initial large backups, keep the app open in foreground

**Note**: On iOS, videos may not upload in the background due to size - they'll sync when you next open the app.

Learn more in the [Background sync guide](/photos/features/backup-and-sync/#background-sync).

### Does background sync work on web? {#background-sync-web}

No, background sync is not available when using Ente Photos through a web browser. Web browsers don't allow background processes to run when the tab is closed or inactive.

Background sync is only available on:

- Mobile apps (iOS and Android)
- Desktop app (via watch folders)

If you're using the web version, you'll need to keep the browser tab open for uploads to complete.

### How does background sync work on iOS? {#ios-background-sync}

On iOS, background sync works through silent push notifications:

- Our servers "tickle" your device periodically
- This wakes up the app and gives it 30 seconds to sync
- Videos may not upload in background due to size limitations

**Important**: If you force-kill the app from recents, iOS won't deliver push notifications and background sync will stop working.

For large initial backups, keep the app open in foreground on iOS.

### How does background sync work on Android? {#android-background-sync}

On Android, the app can run background processes more freely than iOS. However, battery optimization settings can interfere.

**Make sure to**:

- Disable "Optimize battery usage" for Ente
- Grant all required permissions
- Don't force-close the app from recents

**Note**: On Android 15+, if the app is in private space and private space is locked, background sync won't work.

## Desktop Backup (Watch Folders)

### How do watch folders work? {#how-watch-folders-work}

Watch folders allow the Ente desktop app to automatically monitor specific directories on your computer and sync any changes to Ente. When you add or modify files in a watched folder, they're automatically uploaded.

**Key features:**

- One-way sync from your computer to Ente
- Monitors folders in real-time
- Automatically uploads new files
- Moves files to uncategorized if deleted locally
- Preserves folder structure as albums

Learn more in the [Watch folders feature guide](/photos/features/backup-and-sync/watch-folders).

### What are watch folders? {#what-are-watch-folders}

Watch folders is a desktop app feature that automatically syncs specific folders on your computer to Ente. Once you add a folder to watch, the app will:

- Immediately upload all existing files in that folder
- Continuously monitor the folder for changes
- Automatically upload any new files added to the folder
- Move files to Uncategorized if you delete them locally

This creates a one-way background sync from your computer to Ente, automating your photo backup workflow.

### How do I set up watch folders? {#set-up-watch-folders}

1. Open the Ente desktop app
2. Click "Watch folders" in the sidebar
3. Click "Add folder" and select the folder you want to watch (or drag and drop it)
4. If the folder has nested subfolders, choose between:
    - **Single album**: All files go into one Ente album
    - **Separate albums**: Each subfolder becomes its own album
5. The folder will be initially synced and then monitored for changes

The sync happens in the background even when the app is minimized. You can see progress in the bottom right corner.

### Can I watch multiple folders at once? {#watch-multiple-folders}

Yes! You can add as many watch folders as you need. Each folder can be configured independently:

- Different folders can sync to different albums
- Each can have its own single/separate album setting
- All watched folders sync simultaneously in the background

To manage your watch folders, click "Watch folders" in the sidebar to see the list of all folders being watched.

### What happens if I delete a file from my watched folder? {#delete-from-watched-folder}

If you delete a file from a watched folder on your computer, the corresponding file in Ente will be automatically moved to the [Uncategorized](/photos/faq/albums-and-organization#uncategorized) album. It won't be permanently deleted - you can still access it from the Uncategorized section.

If you want to remove it completely from Ente, you'll need to manually delete it from the Uncategorized album.

### Why are my watch folders not syncing? {#watch-folders-not-syncing}

Common issues and solutions:

1. **Desktop app is closed**: Watch folders only sync when the desktop app is running. Enable "Launch at startup" in preferences.

2. **Network issues**: Check your internet connection. The sync will automatically resume when connectivity is restored.

3. **Upload in progress**: If you're manually uploading files, watch folder syncing pauses and resumes when the upload completes.

4. **File format not supported**: Check if the files are valid image/video formats. The app may skip unsupported files.

5. **Storage quota exceeded**: Verify you haven't reached your storage limit in Settings.

Check the sync status indicator in the bottom right corner for error details.

### Can I watch folders on a network drive (NAS)? {#watch-nas}

**Not recommended**. The Ente desktop app currently does not officially support NAS (network drives).

While the app may work with network drives in some cases, we've found that network storage products often have:

- Flaky file system emulation
- Bad performance during uploads
- Unreliable file change event notifications (critical for watch folders)

**We strongly recommend** temporarily copying files to your local storage for uploads, rather than watching folders that live on a network drive.

**Exception**: Exports to network drives generally work better than imports. See [Advanced Features](/photos/faq/advanced-features) for export details.

### How do I stop watching a folder? {#stop-watching-folder}

1. Click "Watch folders" in the sidebar
2. Find the folder you want to stop watching
3. Click the three dots next to that folder entry
4. Select "Stop watching"

The folder will no longer be monitored, but all files that were already uploaded to Ente will remain there. Stopping watch does not delete any photos from Ente.

### Can watch folders preserve my nested folder structure? {#watch-nested-structure}

Yes! When you add a folder with nested subfolders, you'll see two options:

**Separate albums mode**:

- Creates a separate Ente album for each nested folder
- Only the leaf folder name is used (e.g., both `Photos/2024/Summer` and `Backup/Summer` go to an album called "Summer")
- Empty folders or folders containing only other folders are ignored
- Albums cannot be nested in Ente (they'll all appear as top-level albums)

**Single album mode**:

- All files from all nested folders go into one Ente album
- The folder structure is flattened
- Good for when you don't need to preserve organization

Learn more about [Preserving folder structure](/photos/features/albums-and-organization/albums#preserving-folder-structure).

### Does watch folder syncing pause when I close the desktop app? {#watch-folder-requires-app}

Yes. Watch folders only sync when the Ente desktop app is running. To ensure continuous automatic backup:

1. Keep the desktop app running (it can be minimized)
2. Enable "Launch at startup" in Preferences so the app starts automatically when you boot your computer
3. The app will sync in the background without interrupting your work

### Can I change watch folder settings after setting it up? {#change-watch-settings}

Currently, you cannot directly change the album configuration (single vs separate) for an existing watch folder. However, you can:

1. Stop watching the folder
2. Remove the folder from the watch list
3. Re-add it with the desired settings

Ente will detect already-uploaded files and skip them, so you won't end up with duplicates.

### How does watch folders handle duplicates? {#watch-folder-dedup}

Watch folders use the same automatic duplicate detection as regular uploads:

- If a file already exists in the target album, it will be skipped
- If uploading to a different album, a symlink (reference) is created instead of re-uploading
- This saves storage space and upload time

You can safely add the same folder multiple times or re-add folders after stopping watch - duplicates will be automatically handled.

Learn more in the [Duplicate detection guide](/photos/features/backup-and-sync/duplicate-detection).

### Can I watch a folder and manually upload to it at the same time? {#watch-and-manual-upload}

If you start a manual upload while watch folder sync is in progress, the watch folder sync will pause and resume automatically when your manual upload completes.

This ensures smooth operation and prevents conflicts.

## General Backup Questions

### Can I backup photos from my computer? {#backup-from-computer}

Yes! On desktop, you have two options:

1. **Watch folders**: Automatically sync specific folders (recommended for ongoing backup)
    - Continuous monitoring and automatic uploads
    - See watch folders section above

2. **Manual upload**: Drag and drop files or folders into the Ente desktop app
    - Good for one-time uploads
    - Can upload ZIP files
    - Preserves folder structure

### Can I pause and resume backups? {#pause-resume-backup}

**On mobile:**
You can effectively pause backups by:

- Turning off WiFi/mobile data
- Going to `Settings > Backup` and toggling off specific albums

To resume, simply turn connectivity back on or re-enable the albums.

**On desktop:**

- Watch folder syncing will pause if you close the app
- You can remove watch folders temporarily and re-add them later
- Uploads can be paused by closing the desktop app

### Why are some photos not uploading? {#photos-not-uploading}

Common reasons and solutions:

1. **Storage quota exceeded**: Check your storage in Settings and upgrade if needed
2. **Network issues**: Verify internet connectivity
3. **Battery optimization** (Android): Disable for Ente in system settings
4. **Background App Refresh** (iOS): Enable in device Settings > Ente
5. **File format not supported**: Check if the file meets Ente's requirements
6. **File too large**: Maximum file size is 10 GB

For detailed troubleshooting, see [Troubleshooting](/photos/faq/troubleshooting).

### Can I use the desktop app and mobile app at the same time? {#use-multiple-devices}

Yes! You can use Ente on as many devices as you want simultaneously. All your devices will stay in sync:

- Photos uploaded from any device appear on all devices
- Albums, edits, and organization sync across devices
- Each device can have its own backup/watch folder settings

The sync happens automatically in the background when devices are connected to the internet.

## File Support & Upload Limits

### What file formats does Ente support? {#file-formats}

Ente supports all files that have a mime type of `image/*` or `video/*` regardless of their specific format.

However, we only have limited support for RAW currently. We are working towards adding full support, and you can watch this [thread](https://github.com/ente-io/ente/discussions/625) for updates.

If you find an issue with ente's ability to parse a certain file type, please write to [support@ente.io](mailto:support@ente.io) with details of the unsupported file format and we will do our best to help you out.

### Is there a file size limit? {#file-size-limit}

Yes, we currently do not support files larger than 10 GB.

### Does Ente support videos? {#video-support}

Ente supports backing up and downloading of videos in their original format and quality.

But some of these formats cannot be streamed on the web browser and you will be prompted to download them.

### Does Ente apply compression to uploaded photos? {#compression}

Ente does not apply compression to uploaded photos. The file size of your photos in Ente will be similar to the original file sizes you have.

## Deduplication

### How does the deduplication feature work on the desktop app? {#deduplication-desktop}

If the app finds exact duplicates, it will show them in the manual deduplication tool. When you confirm removal, the app keeps one copy and creates symlinks for the duplicates in all albums. This helps save storage space while maintaining your album structure.

Learn more about [manually removing duplicates](/photos/features/albums-and-organization/storage-optimization) and [automatic duplicate detection during backup](/photos/features/backup-and-sync/duplicate-detection).
