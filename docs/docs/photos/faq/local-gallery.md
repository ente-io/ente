---
title: Gallery FAQ
description: Frequently asked questions about using Ente Photos in offline mode without an account
---

# Gallery

## Getting Started {#getting-started}

### How do I use Ente without creating an account? {#use-without-account}

On the welcome screen, tap **Continue without account**. Grant photo library access when prompted. You can now browse your device photos, use face recognition, magic search, and other on-device features without signing up.

### Why don't I see the "Continue without account" button? {#no-offline-button}

The offline mode option is controlled by a feature flag. If you don't see the button, make sure you're running the latest version of Ente Photos. If it still doesn't appear, the feature may not be available in your region yet.

### What permissions does Ente need in offline mode? {#offline-permissions}

Ente needs access to your photo library to display your photos. On iOS, grant "Allow access to all photos" for the best experience. On Android, grant media/photo access. No network permissions are needed since offline mode doesn't upload anything.

## Features {#features}

### Does face recognition work without an account? {#offline-face-recognition}

Yes. Face recognition runs entirely on your device in offline mode. Enable it from the banner on the Search tab or from `Settings > Machine learning`. All processing happens locally -- no data leaves your phone.

### Does magic search work without an account? {#offline-magic-search}

Yes. Natural language search (magic search) also runs on-device. After enabling ML, Ente indexes your photos locally so you can search using descriptions like "beach sunset" or "birthday cake".

### Can I use the map view in offline mode? {#offline-map}

Yes. If your photos contain location metadata, enable map view from `Settings > Map`. The map displays photo locations using the GPS data embedded in your photos.

### Do memories work in offline mode? {#offline-memories}

Yes. Memories appear at the top of the home gallery based on photos from past years on your device.

### Can I favorite photos in offline mode? {#offline-favorites}

No. Favorites is an Ente cloud album and requires an account. In offline mode, you can browse and view all your device photos but cannot organize them into Ente albums.

### Can I share photos from offline mode? {#offline-sharing}

You can share individual photos to other apps using the standard share sheet (share button in the viewer). However, Ente's album sharing, collaborative albums, and public links require an account.

## Signing Up {#signing-up}

### How do I create an account from offline mode? {#create-account-from-offline}

There are three places to sign up:

1. Tap the **Get started** banner at the top of the home gallery
2. Tap the **Enable backup** prompt in the Albums tab
3. Open **Settings** and tap the sign-in card at the top

### Will I lose my photos or ML data when I sign up? {#data-preserved-on-signup}

No. All your device photos remain on your device, and any ML processing (face recognition, search embeddings) done in offline mode is preserved. Signing up adds cloud features on top of your existing local experience.

### Can I go back to offline mode after signing up? {#return-to-offline}

Once you sign in to an Ente account, the app operates in signed-in mode. To return to offline mode, you would need to sign out.

## Troubleshooting {#troubleshooting}

### My photos aren't showing up in offline mode {#photos-not-showing-offline}

1. Check that Ente has photo library access in your device's system settings
2. On iOS, confirm you granted **Allow access to all photos** (not "Selected photos")
3. Wait for the initial scan to complete -- check the status bar at the top of the gallery
4. Close and reopen Ente to trigger a fresh scan

### ML indexing seems slow {#slow-ml-indexing}

On-device ML processing can take time, especially for large libraries. Keep the app open and charging for faster processing. The ML progress banner on the Search tab shows current progress.

### The app uses a lot of battery {#battery-usage-offline}

ML indexing is processor-intensive. Once initial indexing completes, battery usage returns to normal. To pause indexing, disable ML from `Settings > Machine learning`.

## Related topics

- [Gallery feature guide](/photos/features/local-gallery)
- [Machine learning](/photos/features/search-and-discovery/machine-learning)
- [Face recognition](/photos/features/search-and-discovery/face-recognition)
- [Backup and sync](/photos/features/backup-and-sync/) (after signing up)
