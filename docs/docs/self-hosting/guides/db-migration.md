---
title: DB Migration
description: Migrating your self hosted Postgre 12 database to Postgres 16
---

# Migrating Postgres 12 to 16

The old sample docker compose file used Postgres 12, which is now nearing end of
life, so we've updated it to Postgres 16. Postgres major versions require a
migration step. This document outlines one possible approach.

> [!TIP]
>
> Ente itself does not use any specific Postgres 12 or Postgres 16 features, and
> will talk to either happily.

### Taking a backup

`docker compose exec` allows us to run a command against a running container. We
can use it to run the `pg_dumpall` command on the postgres container to create a
plaintext backup.

Assuming your cluster is already running, and you are in the `ente/server`
directiory, you can run the following (this command uses the default
credentials, you'll need to change these to match your setup):

```sh
docker compose exec postgres env PGPASSWORD=pgpass PGUSER=pguser PG_DB=ente_db pg_dumpall >pg12.backup.sql
```

This will produce a `pg12.backup.sql` in your current directory. You can open it
in a text editor (it can be huge!) to verify that it looks correct.

We won't be needing this file, this backup is recommended just in case something
goes amiss with the actual migration.

> If you need to restore from this plaintext backup, you could subsequently run
> something like:
>
> ```sh
> cat pg12.backup.sql | docker compose exec -T postgres env PGPASSWORD=pgpass psql -U pguser -d ente_db
> ```

## The migration

At the high level, the steps are

1. Stop your cluster

2. Start just the postgres container after changing the image to
   `pgautoupgrade/pgautoupgrade:16-bookworm'

3. Once the in-place migration completes, stop the container, and change the
   image to `postgres:16`

#### 1. Stop the cluster

Stop your running Ente cluster.

```sh
docker compose down
```

#### 2. Run `pgautoupgrade`

Modify your `compose.yaml`, changing the image for the "postgres" container from
"postgres:12" to "pgautoupgrade/pgautoupgrade:16-bookworm"

```diff
diff a/server/compose.yaml b/server/compose.yaml

   postgres:
-    image: postgres:12
+    image: pgautoupgrade/pgautoupgrade:16-bookworm
     ports:
```

[pgautoupgrade](https://github.com/pgautoupgrade/docker-pgautoupgrade) is a
community docker image that performs an in-place migration.

After making the change, run only the `postgres` container in the cluster

```sh
docker compose up postgres
```

The container will start and peform an in-place migration. Once it is done, it
will start postgres normally. You should see something like this is the logs

```
postgres-1  | Automatic upgrade process finished with no errors reported
...
postgres-1  | ...  starting PostgreSQL 16.4 ...
```

At this point, you can stop the container (`CTRL-C`).

#### 3. Finish by changing image

Modify `compose.yaml` again, changing the image to "postgres:16".

```diff
diff a/server/compose.yaml b/server/compose.yaml

   postgres:
-    image: pgautoupgrade/pgautoupgrade:16-bookworm
+    image: postgres:16
     ports:
```

Migration is now complete. You can start your Ente cluster normally.

```sh
docker compose up
```
