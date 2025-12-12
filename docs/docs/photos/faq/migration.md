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

### Can I retry failed uploads?

Yes. You can check the progress/info tab that appears during upload to determine the cause of failed uploads. You can also drag and drop the folder or files again. Ente will automatically ignore already backed up files and try to upload just the rest.
