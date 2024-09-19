---
title: DB Migration
description:
    Migrating your self hosted Postgres 12 database to newer Postgres versions
---

# Migrating Postgres 12 to 15

The old sample docker compose file used Postgres 12, which is now nearing end of
life, so we've updated it to Postgres 15. Postgres major versions changes
require a migration step. This document mentions some approaches you can use.

> [!TIP]
>
> Ente itself does not use any specific Postgres 12 or Postgres 15 features, and
> will talk to either happily. It should also work with newer Postgres versions,
> but let us know if you run into any problems and we'll update this page.

### Taking a backup

`docker compose exec` allows us to run a command against a running container. We
can use it to run the `pg_dumpall` command on the postgres container to create a
plaintext backup.

Assuming your cluster is already running, and you are in the `ente/server`
directory, you can run the following (this command uses the default credentials,
you'll need to change these to match your setup):

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
> docker compose up postgres
> cat pg12.backup.sql | docker compose exec -T postgres env PGPASSWORD=pgpass psql -U pguser -d ente_db
> ```

## The migration

At the high level, the steps are

1. Stop your cluster.

2. Start just the postgres container after changing the image to
   `pgautoupgrade/pgautoupgrade:15-bookworm`.

3. Once the in-place migration completes, stop the container, and change the
   image to `postgres:15`.

#### 1. Stop the cluster

Stop your running Ente cluster.

```sh
docker compose down
```

#### 2. Run `pgautoupgrade`

Modify your `compose.yaml`, changing the image for the "postgres" container from
"postgres:12" to "pgautoupgrade/pgautoupgrade:15-bookworm"

```diff
diff a/server/compose.yaml b/server/compose.yaml

   postgres:
-    image: postgres:12
+    image: pgautoupgrade/pgautoupgrade:15-bookworm
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
postgres-1  | ...  starting PostgreSQL 15...
```

At this point, you can stop the container (`CTRL-C`).

#### 3. Finish by changing image

Modify `compose.yaml` again, changing the image to "postgres:15".

```diff
diff a/server/compose.yaml b/server/compose.yaml

   postgres:
-    image: pgautoupgrade/pgautoupgrade:15-bookworm
+    image: postgres:15
     ports:
```

And cleanup the temporary containers by

```sh
docker compose down --remove-orphans
```

Migration is now complete. You can start your Ente cluster normally.

```sh
docker compose up
```

## Migration elsewhere

The above instructions are for Postgres running inside docker, as the sample
docker compose file does. There are myriad other ways to run Postgres, and the
migration sequence then will depend on your exact setup.

Two common approaches are

1. Backup and restore, the `pg_dumpall` + `psql` import sequence described in
   [Taking a backup](#taking-a-backup) above.

2. In place migrations using `pg_upgrade`, which is what the
   [pgautoupgrade](#the-migration) migration above does under the hood.

The first method, backup and restore, is low tech and will work similarly in
most setups. The second method is more efficient, but requires a bit more
careful preparation.

As another example, here is how one can migrate 12 to 15 when running Postgres
on macOS, installed using Homebrew.

1. Stop your postgres. Make sure there are no more commands shown by
   `ps aux | grep '[p]ostgres'`.

2. Install postgres15.

3. Migrate data using `pg_upgrade`:

    ```sh
    /opt/homebrew/Cellar/postgresql@15/15.8/bin/pg_upgrade -b /opt/homebrew/Cellar/postgresql@12/12.18_1/bin -B /opt/homebrew/Cellar/postgresql@15/15.8/bin/ -d /opt/homebrew/var/postgresql@12 -D /opt/homebrew/var/postgresql@15
    ```

4. Start postgres 15 and verify version using `SELECT VERSION()`.
