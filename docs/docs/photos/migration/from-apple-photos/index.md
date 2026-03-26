---
title: Import from Apple Photos
description: Migrating your existing photos from Apple Photos to Ente Photos
---

# Import from Apple Photos

## Mobile

If you are using Apple Photos on your phone, then the most seamless way is to
install the Ente app on your mobile device. The Ente app will directly read from
your iCloud library and import.

> [!TIP]
>
> For large libraries, this process may take a bit of time, so you can speed it
> up by keeping the app running in the foreground while the initial import is in
> progress. You can do this by going to `Settings > Backup > Backup settings` and
> turning on "Disable auto lock"
> (Note: this is only needed during the initial import, subsequently
> the app will automatically backup photos in the background as you take them).

## Importing iCloud Shared Photo Library to Ente

iCloud Shared Photo Library lets up to 6 people share a unified photo
collection. Ente does not have an equivalent feature — instead, Ente offers
[shared and collaborative albums](/photos/features/sharing/) on a per-album
basis.

To migrate photos from iCloud Shared Photo Library to Ente, on mobile, you need
to first move them into your personal iCloud library, then import them into
Ente.

### 1. Move Shared Library photos to your Personal Library

**On iPhone or iPad:**

1. Open `Settings > (Apps >) Photos > Shared Library`.
2. Tap **Leave Shared Library** (or **Delete Shared Library** if you are the
   organizer).
3. When prompted, choose **Keep Everything** to copy every photo from the Shared
   Library into your Personal Library.

> [!IMPORTANT]
>
> Make sure iCloud Photos has fully synced before leaving the Shared Library.
> Open `Settings > Photos` and confirm the sync status shows "Up to Date". If
> photos have not finished downloading, you may end up with lower-resolution
> copies or missing files.

> [!TIP]
>
> If you do not want to leave the Shared Library yet, you can also manually
> select photos in the Shared Library view and move them to your Personal
> Library without leaving.

### 2. Import into Ente

Once the photos are in your Personal Library, install the Ente app on your
iPhone. It will directly read from your iCloud library and back up everything,
including the photos you just moved from the Shared Library.

### 3. What about metadata?

- **EXIF data** (dates, location, camera info) embedded in photo files is
  preserved during import.
- **Favorites, album membership, and People tags** are stored only inside Apple
  Photos and are not embedded in exported files.

### Desktop alternative

If mobile is not an option, on macOS you can directly export photos from the
Shared Library view without moving them to your Personal Library first.

1. Open the Photos app and switch to **Shared Library** view using the library
   selector in the toolbar.
2. Select all photos (`Command + A`).
3. Click `File > Export > Export Unmodified Originals` and choose a destination
   folder.

For information regarding desktop migration, please go through this
[FAQ](/photos/faq/migration#importing-from-apple-photos).

If you run into any issues during this migration, please reach out to
[support@ente.io](mailto:support@ente.io) and we will be happy to help you!
