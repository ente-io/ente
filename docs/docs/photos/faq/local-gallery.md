---
title: Local Gallery FAQ
description: Frequently asked questions about the local gallery, device folders, and offline mode in Ente Photos
---

# Local Gallery

## Device Folders {#device-folders}

### What are device folders in Ente? {#what-are-device-folders}

Device folders (also called "On device" albums) are the albums and folders from your phone's native photo library that Ente can see. They appear in the Albums tab as a horizontal row at the top. These reflect your device's album structure (e.g., Camera, Screenshots, WhatsApp Images) and are separate from Ente's cloud albums.

### Why don't I see any device folders? {#no-device-folders}

If device folders aren't showing up, check the following:

1. **Photo library permission**: Make sure Ente has access to your device's photo library. Go to your device's Settings > Apps > Ente Photos and ensure photo/media access is granted.
2. **Permission level (iOS)**: On iOS, if you selected "Allow access to selected photos" instead of "Allow access to all photos", Ente can only see the specific photos you selected, which may not include complete albums.
3. **First sync not complete**: Device folders appear after the initial local scan completes. Wait a moment and pull down to refresh.

### Can I rename or reorganize device folders in Ente? {#rename-device-folders}

No. Device folders in Ente are a read-only view of your device's photo library structure. To rename or reorganize them, use your device's native photos app (e.g., Apple Photos on iOS, Google Photos or Files on Android). Changes will be reflected in Ente after the next sync.

### Are device folders the same as Ente albums? {#device-vs-ente-albums}

No. Device folders and Ente albums are separate concepts:

- **Device folders** reflect your phone's native album structure and contain only local files
- **Ente albums** are cloud-based collections that sync across all your devices

When you enable backup for a device folder, Ente creates a corresponding cloud album with the same name. But after that, the two are independent - adding photos to the Ente album doesn't add them to the device folder, and vice versa.

## Backup {#backup}

### How do I back up a specific device folder? {#backup-specific-folder}

Open the device folder from the Albums tab, then toggle the **Backup** switch at the top. Alternatively, go to `Settings > Backup > Backed up folders` to manage all folder selections at once.

### What happens when I enable backup for a folder? {#enable-backup}

When you enable backup for a device folder:

1. All existing photos and videos in that folder are queued for upload
2. A corresponding Ente album is created with the same name
3. New photos added to that folder will be automatically uploaded in the background
4. The upload respects your network preferences (WiFi-only by default)

### Can I back up all folders at once? {#backup-all-folders}

Yes. During initial setup, you can choose to back up all folders. After setup, go to `Settings > Backup > Backed up folders` and select all folders, or use the select all option if available.

### Why are some photos in a backed-up folder not uploading? {#photos-not-uploading}

Some files might be skipped during backup if:

- The upload was interrupted (network issue, app closed)
- The file format is not supported
- The file was in a temporary error state

These files are tracked as "ignored files." To retry them, open the device folder and tap **Reset ignored files**. This clears the ignored list and queues those files for upload on the next sync.

### Do I need to keep the app open for backup to work? {#background-backup}

No. Ente supports background sync on both iOS and Android. However, there are platform-specific considerations:

- **iOS**: The initial backup of a large library may require keeping the app in the foreground. Subsequent backups work in the background. Videos are only backed up when the app is open. Do not force-kill the app from recents.
- **Android**: Make sure "Optimize battery usage" is disabled for Ente in your device's system settings.

See [Background sync](/photos/features/backup-and-sync/#background-sync) for details.

## Offline Mode {#offline-mode}

### Can I use Ente without creating an account? {#use-without-account}

Yes. Ente Photos can be used purely as a local gallery app without signing up. In this mode, you can browse your device photos, view them in the full-featured viewer, and even use on-device ML features like face recognition and natural language search.

### What features work in offline mode? {#offline-features}

In offline mode (no account), you can:

- Browse all device folders and photos
- View photos and videos
- Use on-device ML (face recognition, magic search) if enabled
- View photos on a map (requires location data in photos)
- Use the photo viewer with zoom, swipe, and sharing to other apps

Features that require an account:

- Cloud backup and cross-device sync
- Ente albums, Favorites, Uncategorized
- Sharing and collaborative albums
- Cross-device ML sync (face names, etc.)
- Memories

### How do I switch from offline mode to having an account? {#switch-to-online}

You can sign up at any time from the app. Your local gallery and any ML indexes built in offline mode will be preserved. After signing up, you can select which device folders to back up to Ente's cloud.

### Will I lose my data if I switch from offline to online mode? {#data-loss-switching}

No. Switching from offline mode to an Ente account preserves all your local data. Your device photos remain on your device, and any ML processing (face recognition, embeddings) that was done locally is kept. You then gain the additional ability to back up to the cloud and use online features.

## Storage and Cache {#storage}

### How much storage does the local gallery cache use? {#cache-size}

Ente caches thumbnails from your device's photo library to improve scrolling performance. You can check and clear this cache in `Settings > Storage > Manage device storage` under the "Local gallery" entry. Clearing the cache is safe - thumbnails are regenerated as you browse.

### Does viewing device photos in Ente use extra storage? {#extra-storage}

Ente creates a small thumbnail cache for smoother browsing, but it does not duplicate your full-resolution photos. The cache can be cleared at any time without data loss.

### How do I free up space on my device after backing up? {#free-up-space}

Go to `Settings > Backup > Free up space`. Ente will show you how much space can be reclaimed by deleting local copies of photos that have been fully backed up. Only fully uploaded files are eligible for removal.

Learn more in [Storage optimization](/photos/features/albums-and-organization/storage-optimization).

## Troubleshooting {#troubleshooting}

### Device folders are empty or missing photos {#empty-folders}

Try these steps:

1. **Check permissions**: Ensure Ente has full photo library access in your device settings
2. **Wait for sync**: The local scan may still be in progress - check the status bar at the top of the gallery
3. **Restart the app**: Close and reopen Ente to trigger a fresh scan
4. **Check iOS permission level**: On iOS, make sure you granted "Allow access to all photos" rather than selecting individual photos

### Photos deleted from my device still show in Ente {#deleted-still-showing}

This is expected behavior. Ente is a backup service, not a two-way sync. Photos backed up to Ente remain in your Ente account even after you delete them from your device. To remove them from Ente as well, delete them manually within the Ente app.

### Backup is stuck or not progressing {#backup-stuck}

If backup seems stuck:

1. Check your network connection
2. Make sure background sync is not restricted (see [Background sync](/photos/features/backup-and-sync/#background-sync))
3. Open the app and leave it in the foreground for a few minutes to allow uploads to progress
4. Check `Settings > Backup` for any error indicators
5. Try toggling backup off and on for the affected folder

### Some device folders show "0 photos" {#zero-photos}

This can happen when:

- The folder contains only unsupported file types
- The media scanner hasn't indexed those files yet
- The files were recently added and the local sync hasn't completed

Pull down to refresh, or restart the app to trigger a rescan.

## Related topics

- [Local gallery feature guide](/photos/features/local-gallery)
- [Backup and sync](/photos/features/backup-and-sync/)
- [Storage optimization](/photos/features/albums-and-organization/storage-optimization)
- [Albums and Organization FAQ](/photos/faq/albums-and-organization)
- [Troubleshooting](/photos/faq/troubleshooting)
