---
title: Docker errors
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

      while ! mc config host add h0 http://minio:3200 changeme changeme1234
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
