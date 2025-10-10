---
title: Advanced Features FAQ
description: Frequently asked questions about CLI, exports, and advanced features in Ente Photos
---

# Advanced Features

## Command Line Interface (CLI)

### What is the Ente CLI? {#what-is-cli}

The Ente CLI is a command-line tool for advanced users that allows you to:

- Export your entire library or specific albums to local storage
- Set up automated exports with cron jobs
- Sync data to NAS or other storage systems
- Perform bulk operations

The CLI is particularly useful for:

- Regular automated backups to local/NAS storage
- Server-to-server transfers
- Power users who prefer command-line tools

For complete details, see the [CLI feature guide](/photos/features/utilities/cli).

### How do I install the CLI? {#install-cli-advanced}

Ente's CLI is distributed directly over [GitHub](https://github.com/ente-io/ente/releases?q=tag%3Acli-v0).

Download the appropriate version for your platform and follow the installation instructions in the [CLI README](https://github.com/ente-io/ente/tree/main/cli#readme).

Learn more in the [CLI installation guide](/photos/features/utilities/cli#installation).

### How do I use the CLI to export my photos? {#cli-export-photos}

The CLI supports incremental exports, which means it will only download new or changed files:

```bash
# Export all photos
ente export

# Export to specific directory
ente export --dir /path/to/backup

# Export specific album
ente export --album "Album Name"
```

The exports are incremental and will gracefully handle interruptions - you can safely stop and restart without re-downloading everything.

For complete documentation, see the [CLI feature guide](/photos/features/utilities/cli#basic-usage).

### How do I keep NAS and Ente photos synced? {#nas-sync}

The recommended approach is to use the CLI to pull data from Ente to your NAS:

1. Install the CLI on your NAS or a machine that can access it
2. Set up a cron job to run periodic exports
3. Use the CLI's incremental export feature

Example cron job for daily sync:

```bash
0 2 * * * /usr/local/bin/ente export --dir /nas/ente-backup
```

See the [CLI NAS sync guide](/photos/features/utilities/cli#nas-sync-setup) for detailed setup.

**Note**: Two-way sync is not currently supported. The CLI pulls data from Ente to your local storage.

### CLI not found after installation {#cli-not-found}

Make sure the CLI binary is in your PATH or use the full path to execute it.

### CLI authentication issues {#cli-auth-issues}

If login fails, try:

- Verify your email and password are correct
- Check your internet connection
- Ensure you're using the latest CLI version

### CLI export interruptions {#cli-export-interruptions}

The CLI handles interruptions gracefully. Simply run the export command again - it will resume from where it stopped.

### NAS export issues with CLI {#cli-nas-export}

If exporting to NAS using CLI:

- Ensure the NAS mount is accessible
- Check write permissions on the destination folder
- Use a local path if the NAS is mounted on your system

## Exporting from Desktop/Web

### How can I backup my data locally outside Ente? {#local-backup}

You can use our CLI tool or our desktop app to set up exports of your data to your local drive. This way, you can use Ente in your day to day use, with an additional guarantee that a copy of your original photos and videos are always available on your machine.

**Desktop app**:

Open `Settings > Export data`, choose a destination folder, and enable "Continuous export" to automatically export new items.

**CLI**:
Use [Ente's CLI](https://github.com/ente-io/ente/tree/main/cli#export) to export your data in a cron job to a location of your choice. The exports are incremental, and will also gracefully handle interruptions.

For complete details, see the [Export feature guide](/photos/features/backup-and-sync/export).

### Does the exported data preserve album structure? {#export-album-structure}

Yes. When you export your data for local backup, it will maintain the exact album structure how you have set up within Ente.

Each album becomes a separate folder, and photos are organized accordingly.

Learn more about [Export album structure](/photos/features/backup-and-sync/export#album-structure).

### Does the exported data preserve metadata? {#export-preserves-metadata}

Yes, the metadata is written out to a separate JSON file during export. Note that the original is not modified.

When you export, suppose you have `flower.png`. You will end up with:

```
flower.png
metadata/flower.png.json
```

Ente writes this JSON in the same format as Google Takeout so that if a tool supports Google Takeout import, it should be able to read the JSON written by Ente too.

Learn more about the metadata format in the [Metadata and Editing FAQ](/photos/faq/metadata-and-editing#export-data-preserve-metadata).

### Can I do a 2-way sync with exports? {#export-two-way-sync}

No, two-way sync is not currently supported. Exports create a one-way sync from Ente to your local storage.

Attempting to export data to the same folder that is also being watched by the Ente app (for uploads) will result in undefined behavior (e.g. duplicate files, export stalling etc).

**Use separate folders for:**

- **Upload source** (watch folders)
- **Export destination** (local backups)

Learn more about [Export limitations](/photos/features/backup-and-sync/export#export-limitations).

### Why is my export size larger than my backed-up size in Ente? {#export-size-larger}

One possible reason could be that you have files that are in multiple different albums. Whenever a file is backed-up to Ente in multiple albums it will still count only once towards the total storage in Ente. However, during export that file will be downloaded multiple times to the different folders corresponding to said albums, causing the total export size to be larger.

**Example:**

- Photo `sunset.jpg` is in albums "Vacation" and "Best Photos"
- In Ente: Counts as 1 file (storage counted once)
- On export: Appears in both `Vacation/` and `Best Photos/` folders (downloaded twice)

Learn more about [Files in multiple albums](/photos/features/backup-and-sync/export#files-in-multiple-albums).

### Can I export to a network drive (NAS)? {#export-to-nas}

Generally, exports are likely to work better than imports when using network drives, since the interaction with the file system is relatively simpler.

**Important note**: If you're exporting to a UNC path (Windows network path like `\\server\share`), the file separators will not work as expected and the export will not start. As a workaround, map your UNC path to a network drive letter and use that instead.

Learn more about [Export to NAS](/photos/features/backup-and-sync/export#network-drives-nas).

### How do I set up continuous exports? {#continuous-export}

**On desktop:**

Open `Settings > Export data`, choose your export folder, and enable "Continuous export".

With continuous export enabled, the app will automatically export new items in the background without you needing to run any manual exports or cron jobs.

The desktop app needs to be running for continuous export to work.

Learn more about [Desktop continuous export](/photos/features/backup-and-sync/export#desktopweb-continuous-export).

## Utilities

### What is video streaming in Ente? {#video-streaming}

Video streaming is a beta feature that lets you watch videos without downloading the entire file first. Ente generates streamable versions (HLS format) that support instant playback and seeking.

For complete details, see the [Video Streaming feature guide](/photos/features/utilities/video-streaming).

### What is a stream technically? {#what-is-a-stream}

A stream is an encrypted HLS file with a `.m3u8` playlist. Ente converts videos to 720p at 2mbps in H.264 format. The stream is encrypted with AES and the playlist with XChaCha20.

Due to encryption, Ente cannot read the contents, duration, or number of chunks within the generated stream.

### Will streams consume space in my storage? {#stream-storage}

While video streaming is in beta, streams do not count against your storage quota. This may change in the future, with options to keep originals only, streams only, or both.

### Video streaming isn't working correctly, what should I do? {#stream-issues}

Video streaming is still in beta. If something isn't working:

- Create a thread in `#feedback` on [Discord](https://discord.com/channels/948937918347608085/1121126215995113552)
- Contact [support@ente.io](mailto:support@ente.io)

For crashes or upload failures with streaming enabled, see [Troubleshooting](/photos/faq/troubleshooting#app-crashes-ml-video).

### How does Cast work? {#how-does-cast-work}

Ente Cast lets you play slideshow albums on Chromecast TVs or any internet-connected large screen. You can pair using auto-pair (Chromium browsers with Chromecast) or PIN pairing (works with any device).

For setup instructions, see the [Cast feature guide](/photos/features/utilities/cast/).

### Can I use Cast without Chromecast? {#cast-without-chromecast}

Yes! Use the "Pair with PIN" option which works with any device. Load [cast.ente.io](https://cast.ente.io) on your large screen device and enter the displayed PIN on your mobile or web device.

### App crashes with video streaming enabled {#app-crashes-video-streaming}

If the app crashes when watching videos or using machine learning, especially on iOS or older devices:

1. Open `Settings > General > Advanced`
2. Disable "Video streaming" or "Enable video playback"
3. Disable "Machine learning" if crashes continue
4. Restart the app

The combination of ML processing and video streaming can exceed available memory on older devices.

### Video upload failures with streaming enabled {#video-upload-failures-streaming}

Large video uploads may fail when streaming is enabled, especially on mobile:

1. Temporarily disable video streaming
2. Upload the videos
3. Re-enable video streaming after upload completes

### My device isn't showing up in Auto Pair for Cast {#cast-auto-pair-not-working}

- Ensure your device and Chromecast are on the same WiFi network
- Check that your Chromecast is properly set up and visible on your network
- Try the "Pair with PIN" option as an alternative

### PIN pairing isn't working for Cast {#cast-pin-not-working}

- Verify that [cast.ente.io](https://cast.ente.io) is loaded on your large screen device
- Check that both devices have internet connectivity
- Make sure you're entering the PIN exactly as displayed (case-sensitive)
- The PIN expires after a short time - refresh for a new PIN if needed

### Photos aren't appearing on the TV {#cast-photos-not-appearing}

- Allow a few moments for the initial connection and loading
- Check that the album you selected has photos in it
- Verify your internet connection on both devices
- Try disconnecting and reconnecting

### What types of notifications does Ente send? {#notification-types}

Ente can send notifications for:

- New photos added to shared albums
- "On this day" memories from previous years
- Birthday reminders for tagged people

Notifications are currently only available on mobile apps. See the [Notifications feature guide](/photos/features/utilities/notifications) for details.

### How do I manage notification settings? {#manage-notifications}

Open `Settings > General > Notifications` to enable or disable specific notification categories. All categories are enabled by default when you grant notification permission.

## Other Advanced Features

### Can I access Ente from multiple browsers? {#multiple-browsers}

Yes! You can access Ente from any browser by going to [web.ente.io](https://web.ente.io) and logging in with your credentials.

Your data syncs across all browsers and devices where you're logged in.

### Does Ente have an API? {#api}

Ente does not currently have a public API for third-party integrations.

However, the CLI provides programmatic access to many features for advanced users. The CLI is open source, so you can also review or extend it for your specific needs.

### Can I self-host Ente? {#self-hosting}

Yes! Ente is open source and can be self-hosted. See our [self-hosting documentation](/self-hosting/) for complete setup instructions.

Note that these FAQs are primarily for Ente's cloud service. Self-hosting has additional considerations documented separately.

### How do I report bugs or request features? {#report-bugs}

You can:

1. **GitHub Issues**: Report bugs or request features on [GitHub](https://github.com/ente-io/ente/issues)
2. **Discord**: Join our [Discord community](https://ente.io/discord) for discussions
3. **Email**: Contact [support@ente.io](mailto:support@ente.io)

For security vulnerabilities, please email [security@ente.io](mailto:security@ente.io) directly.
