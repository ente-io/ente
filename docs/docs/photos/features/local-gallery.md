---
title: Local gallery
description: Browse your device photos and manage backup with the local gallery in Ente Photos
---

# Local gallery

The local gallery in Ente Photos lets you browse photos and videos stored on your mobile device, organized by the same albums and folders you see in your native photos app. From here you can choose which folders to back up to Ente, manage device storage, and use Ente as a gallery app even without an account.

> **Availability**: The local gallery is available on the **Ente Photos mobile app** (iOS and Android). On desktop, a similar role is served by [watch folders](/photos/features/backup-and-sync/watch-folders).

## How it works

When you grant Ente access to your device's photo library, the app scans your device for photos and videos and groups them by their native album or folder (for example, "Camera", "Screenshots", "WhatsApp Images"). These are called **device folders** or **on-device albums**.

Device folders appear in the **Albums** tab of the app as a horizontal scrollable row at the top, showing each folder's name, photo count, and a thumbnail preview.

Key points:

- **Read-only view of device structure** - Ente reads the album structure from your device's photo library. It does not modify or reorganize your device files.
- **Separate from Ente albums** - Device folders are distinct from Ente (cloud) albums. A device folder becomes an Ente album only when you enable backup for it.
- **Per-folder backup control** - You choose which device folders to back up. Folders you don't select remain visible locally but are not uploaded.

## Viewing device folders

### On mobile

1. Open the **Albums** tab
2. At the top you'll see a horizontal row of your device folders
3. Tap any folder to browse its contents

Inside a device folder you'll see all photos and videos organized by date, just like the main gallery.

## Selecting folders for backup {#selecting-backup-folders}

You can choose which device folders should be automatically backed up to Ente.

### During setup

When you first create an Ente account, the app will prompt you to select which albums to back up. You can select individual folders or choose to back up all folders.

### After setup

To change your backup selections later:

**From a device folder:**

1. Open a device folder from the Albums tab
2. Toggle the **Backup** switch at the top of the folder
3. When enabled, all photos in that folder will be uploaded to Ente

**From Settings:**

1. Open `Settings > Backup > Backed up folders`
2. Select or deselect folders as needed

When backup is enabled for a folder:

- Existing photos in the folder are uploaded to Ente
- New photos added to the folder are automatically uploaded in the background
- A corresponding Ente album is created with the same name as the device folder

### Backup indicators

Device folders show visual indicators of their backup status:

- **Cloud icon**: Folder is being backed up to Ente
- **No icon**: Folder is local-only and not being backed up

## Using Ente without an account (offline mode) {#offline-mode}

Ente Photos can be used as a local gallery app without creating an account. In offline mode, you can:

- Browse all device folders and photos
- View photos and videos with the full-featured viewer
- Use on-device ML features (face recognition and magic search) if enabled
- View photos on a map (if location data is available)

### What's not available in offline mode

- Cloud backup and sync
- Sharing and collaborative albums
- Ente albums (Favorites, Uncategorized, etc.)
- Cross-device sync of ML data

### Signing up from offline mode

You can sign up for an Ente account at any time from offline mode. After signing up:

- Your device folders become available for backup selection
- ML indexes built in offline mode are preserved
- You gain access to all cloud features (sharing, cross-device sync, etc.)

## Freeing up device space {#free-up-space}

Once your photos are backed up to Ente, you can delete the local copies to free up device storage:

1. Open `Settings > Backup > Free up space`
2. Review the amount of space that will be freed
3. Confirm to delete backed-up photos from your device

Only photos that have been fully uploaded to Ente will be removed from your device. Your photos remain safely stored in Ente and will be downloaded on demand when you view them.

Learn more in the [Storage optimization guide](/photos/features/albums-and-organization/storage-optimization).

## Ignored files {#ignored-files}

When backup is enabled for a device folder, some files might be skipped during upload (for example, if you cancelled an upload or if a file was in a temporary error state). These are tracked as **ignored files**.

If a device folder has ignored files, you'll see a **Reset ignored files** option inside the folder. Tapping it clears the ignored list and allows those files to be retried on the next sync.

## How local gallery differs from Ente albums

| | Local gallery (device folders) | Ente albums (cloud) |
|---|---|---|
| **Storage location** | Your device | Ente's encrypted cloud |
| **Requires account** | No | Yes |
| **Cross-device sync** | No | Yes |
| **Backup** | Optional, per-folder | Always synced |
| **Organization** | Mirrors device structure | Manually organized |
| **Sharing** | Not available | Full sharing and collaboration |
| **Deletion behavior** | Deleting from device does not delete from Ente | Independent deletion |

## Managing device storage cache

Ente caches thumbnails and previews from your local gallery to improve performance. You can manage this cache in:

`Settings > Storage > Manage device storage`

The **Local gallery** cache entry shows how much space is used for device photo thumbnails. You can clear this cache at any time - thumbnails will be regenerated as needed.

## Tips

- **Selective backup**: You don't need to back up every folder. Consider skipping folders with temporary files (like "Downloads" or "Screenshots") to save cloud storage.
- **Check backup status**: Inside any device folder, the backup toggle shows whether that folder is being synced.
- **Reset ignored files**: If some photos didn't upload, use the "Reset ignored files" option inside the folder to retry them.
- **Offline ML**: Even without an account, you can enable on-device machine learning to search your local photos by faces and content.

## Related topics

- [Backup and sync](/photos/features/backup-and-sync/) - How automatic backup works
- [Watch folders](/photos/features/backup-and-sync/watch-folders) - Desktop equivalent of device folder backup
- [Storage optimization](/photos/features/albums-and-organization/storage-optimization) - Free up space and manage duplicates
- [Machine learning](/photos/features/search-and-discovery/machine-learning) - On-device ML for search and discovery
