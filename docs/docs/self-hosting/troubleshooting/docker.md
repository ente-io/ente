---
title: Docker Errors
description: Fixing docker related errors when trying to self host Ente
---

# Docker

## configs

Remember to restart your cluster to ensure changes that you make in the
`configs` section in `compose.yaml` get picked up.

```sh
docker compose down
docker compose up
```

## post_start

The `server/compose.yaml` Docker compose file uses the "post_start" lifecycle
hook to provision the MinIO instance.

The lifecycle hook **requires Docker Compose version 2.30.0+**, and if you're
using an older version of docker compose you will see an error like this:

```
validating compose.yaml: services.minio Additional property post_start is not allowed
```

The easiest way to resolve this is to upgrade your Docker compose.

If you cannot update your Docker compose version, then alternatively you can
perform the same configuration by removing the "post_start" hook, and adding a
new service definition:

```yaml
minio-provision:
    image: minio/mc
    depends_on:
        - minio
    volumes:
        - minio-data:/data
    networks:
        - internal
    entrypoint: |
        sh -c '
        #!/bin/sh

        while ! mc alias set h0 http://minio:3200 your_minio_user your_minio_pass
        do
          echo "waiting for minio..."
          sleep 0.5
        done

        cd /data

        mc mb -p b2-eu-cen
        mc mb -p wasabi-eu-central-2-v3
        mc mb -p scw-eu-fr-v3
        '
```

## start_interval

Similar to the `post_start` case above, if you are seeing an error like

```
services.postgres.healthcheck Additional property start_interval is not allowed
```

You will need to upgrade your Docker compose version to a newer version that
supports the `start_interval` property on the health check.

## Postgres authentication failed

If you're getting Postgres password authentication failures when starting your
cluster, then you might be using a stale Docker volume.

In more detail, if you're getting an error of the following form (pasting a full
example for easier greppability):

```
museum-1    | panic: pq: password authentication failed for user "pguser"
museum-1    |
museum-1    | goroutine 1 [running]:
museum-1    | main.setupDatabase()
museum-1    |   /etc/ente/cmd/museum/main.go:846 +0x338
museum-1    | main.main()
museum-1    |   /etc/ente/cmd/museum/main.go:124 +0x44c
museum-1 exited with code 2
```

Then the issue is that the password you're using is not the password postgres is
expecting (duh), and a potential scenario where that can happen is something
like this:

1. On a machine, you create a new cluster with `quickstart.sh`.

2. Later you delete that folder, but then create another cluster with
   `quickstart.sh`. Each time `quickstart.sh` runs, it creates new credentials,
   and then when it tries to spin up the docker compose cluster, use them to
   connect to the postgres running within.

3. However, you would already have a docker volume from the first run of
   `quickstart.sh`. Since the folder name is the same in both cases `my-ente`,
   Docker will reuse the existing volumes (`my-ente_postgres-data`,
   `my-ente_minio-data`). So your postgres is running off the old credentials,
   and you're trying to connect to it using the new ones, and the error arises.

The solution is to delete the stale docker volume. **Be careful**, this will
delete all data in those volumes (any thing you uploaded etc), so first
understand if this is the exact problem you are facing before deleting those
volumes.

If you're sure of what you're doing, the volumes can be deleted by

```sh
docker volume ls
```

to list them, and then delete the ones that begin with `my-ente` using
`docker volume rm`. You can delete all stale volumes by using
`docker system prune` with the `--volumes` flag, but be _really_ careful,
that'll delete all volumes (Ente or otherwise) on your machine that are not
currently in use by a running docker container.

An alternative way is to delete the volumes along with removal of cluster's
containers using `docker compose` inside `my-ente` directory.

```sh
docker compose down --volumes
```

If you're unsure about removing volumes, another alternative is to rename your
`my-ente` folder. Docker uses the folder name to determine the volume name
prefix, so giving it a different name will cause Docker to create a volume
afresh for it.

## MinIO provisioning error

If you have used our quickstart script for self-hosting Ente (new users will be unaffected) and are using the default MinIO container for object storage, you may run into issues while starting the cluster after pulling latest images with provisioning MinIO and creating buckets.

You may encounter similar logs while trying to start the cluster:

```
my-ente-minio-1 ->  | Waiting for minio...
my-ente-minio-1 ->  | Waiting for minio...
my-ente-minio-1 ->  | Waiting for minio...
```

MinIO has deprecated the `mc config` command in favor of `mc alias set` resulting in failure in execution of the command for creating bucket using `post_start` hook.

This can be resolved by changing `mc config host h0 add http://minio:3200 $minio_user $minio_pass` to `mc alias set h0 http://minio:3200  $minio_user $minio_pass`

Thus the updated `post_start` will look as follows for `minio` service:

``` yaml
    minio: 
        ...
        post_start:
        - command: |
            sh -c '
            #!/bin/sh

            while ! mc alias set h0 http://minio:3200 your_minio_user your_minio_pass 2>/dev/null
            do
                echo "Waiting for minio..."
                sleep 0.5
            done

            cd /data

            mc mb -p b2-eu-cen
            mc mb -p wasabi-eu-central-2-v3
            mc mb -p scw-eu-fr-v3
            '
```