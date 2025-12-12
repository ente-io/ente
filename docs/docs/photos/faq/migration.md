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

### How can I import Google Photos on mobile? {#google-photos-mobile}

We recommend using desktop for import. Google Takeout exports are often large in size, which can be challenging on mobile due to storage limits, slower processing, and battery drain.

However, if you break the import into smaller chunks, mobile migration is definitely possible.

**Mobile-only migration (slower but works)**

1. Request your Google Takeout on a smaller scale (select specific albums or date ranges rather than everything at once)
2. Download these smaller archives directly to your mobile device
3. Upload them to Ente through the mobile app
4. Repeat for the next batch of photos

**Manual album upload**

Download individual albums from Google Photos to your phone, then upload them to Ente one folder at a time through the mobile app.
