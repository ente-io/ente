---
title: Export FAQ
description: Frequently asked questions about keeping extra backups of your data
---

# Export

## Can I backup my data in a local drive outside Ente?

Yes! You can use our CLI tool or our desktop app to set up exports of your data
in a local drive or NAS of your choice. This way, you can use Ente in your day
to day use, but will have an additional guarantee that a copy of your original
photos and videos are always available in normal directories and files.

* You can use [Ente's CLI](https://github.com/ente-io/ente/tree/main/cli#export)
  to export your data in a cron job to a location of your choice. The exports
  are incremental, and will also gracefully handle interruptions.

* Similarly, you can use Ente's [desktop app](https://ente.io/download/desktop)
  to export your data to a folder of your choice. The desktop app also supports
  "continuous" exports, where it will automatically export new items in the
  background without you needing to run any other cron jobs. See
  [migration/export](/photos/migration/export/) for more details.
