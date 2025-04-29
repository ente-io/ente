---
title: Backups
description: General introduction to backing up your self hosted Ente instance
---

# Backing up your Ente instance

> [!WARNING]
>
> This is not meant to be a comprehensive and bullet proof guide. There are many
> moving parts, and small mistakes might make your backups unusable.
>
> Please treat this only as a general introduction. And remember to test your
> restores.

At the minimum, a functional Ente backend needs three things:

1. Museum (the API server)
2. Postgres (the database)
3. Object storage (any S3-compatible object storage)

When thinking about backups, this translates into backing up the relevant state
from each of these:

1. For museum, you'd want to backup your `museum.yaml`, `credentials.yaml` or
   any other custom configuration that you created. In particular, you should
   backup the
   [secrets that are specific to your instance](https://github.com/ente-io/ente/blob/74377a93d8e20e969d9a2531f32f577b5f0ef090/server/configurations/local.yaml#L188)
   (`key.encryption`, `key.hash` and `jwt.secret`).

2. For postgres, the entire data volume needs to be backed up.

3. For object storage, the entire data volume needs to be backed up.

A common oversight is taking a lot of care for backing up the object storage,
even going as far as enabling replication and backing up the the multiple object
storage volumes, but not applying the same care to the database backup.

While the actual encrypted photos are indeed stored in the object storage,
**this encrypted data will not be usable without the database** since the
database contains information like a file specific encryption key.

Viewed differently, to decrypt your data you need three pieces of information:

1. The encrypted file data itself (which comes from the object storage backup).

2. The ([encrypted](https://ente.io/architecture/)) file and collection specific
   encryption keys (which come from the database backup).

3. The master key (which comes from your password).

---

If you're starting out with self hosting, our recommendation is to start by
keeping a plaintext backup of your photos.
[You can use the CLI or the desktop app to automate this](/photos/faq/export).

Once you get more comfortable with the various parts, you can try backing up
your instance. As a reference,
[this document outlines how Ente itself treats backups](https://ente.io/reliability).

If you stop doing plaintext backups and instead rely on your instance backup,
ensure that you do the full restore process also to verify you can get back your
data. As the industry saying goes, a backup without a restore is no backup at
all.
