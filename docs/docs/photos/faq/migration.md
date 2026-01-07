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

**Best practice**: We [recommend](/photos/migration/from-google-photos/) unzipping all of your Google Takeout zips into a single folder, then importing that folder into Ente. This way, we can always correctly map photos and their metadata.

### Why are my Google Photos dates wrong after import? {#google-photos-dates-wrong}

If the dates appear incorrect after importing from Google Takeout, it's usually because:

- The photo's Exif data has a different date than Google's metadata JSON
- The JSON file wasn't matched with the photo during import

To fix this:

1. Make sure you unzipped all Google Takeout zips into one folder
2. Import that single folder (not individual zips)
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
