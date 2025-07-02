---
title: Export FAQ
description: Frequently asked questions about keeping extra backups of your data
---

# Export

## How can I backup my data in a local drive outside Ente?

You can use our CLI tool or our desktop app to set up exports of your data to
your local drive. This way, you can use Ente in your day to day use, with an
additional guarantee that a copy of your original photos and videos are always
available on your machine.

- You can use [Ente's CLI](https://github.com/ente-io/ente/tree/main/cli#export)
  to export your data in a cron job to a location of your choice. The exports
  are incremental, and will also gracefully handle interruptions.

- Similarly, you can use Ente's [desktop app](https://ente.io/download/desktop)
  to export your data to a folder of your choice. The desktop app also supports
  "continuous" exports, where it will automatically export new items in the
  background without you needing to run any other cron jobs. See
  [migration/export](/photos/migration/export/) for more details.

## Does the exported data preserve album structure?

Yes. When you export your data for local backup, it will maintain the exact
album structure how you have set up within Ente.

## Does the exported data preserve metadata?

Yes, the metadata is written out to a separate JSON file during export. Note
that the original is not modified. For more details, see the
[description of the exported metadata](/photos/faq/metadata#export).

## Can I do a 2-way sync?

A two way sync is not currently supported. Attempting to export data to the same
folder that is also being watched by the Ente app will result in undefined
behaviour (e.g. duplicate files, export stalling etc).

## Why is my export size larger than my backed-up size in Ente?

One possible reason could be that you have files that are in multiple different
albums. Whenever a file is backed-up to Ente in multiple albums it will still
count only once towards the total storage in Ente. However, during export that
file will be downloaded multiple times to the different folders corresponding to
said albums, causing the total export size to be larger.
