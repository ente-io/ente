---
title: Configuring S3 buckets
description:
    Configure S3 endpoints to fix upload errors or use your self hosted ente
    from outside localhost
---

# Configuring S3

## Replication

> [!IMPORTANT]
>
> As of now, replication works only if all the 3 storage type needs are
> fulfilled (1 hot, 1 cold and 1 glacier storage).
>
> For more information, check this
> [discussion](https://github.com/ente-io/ente/discussions/3167#discussioncomment-10585970).

If you're wondering why there are 3 buckets on the MinIO UI - that's because our production instance uses these to perform
[replication](https://ente.io/reliability/).

In a self hosted Ente instance replication is turned off by default. When
replication is turned off, only the first bucket (`b2-eu-cen`) is used, and the
other two are ignored. Only the names here are specifically fixed, but in the
configuration body you can put any other keys.

Use the `s3.hot_storage.primary` option if you'd like to set one of the other
predefined buckets as the primary bucket.

## SSL Configuration

> [!NOTE]
>
> If you need to configure SSL, you'll need to turn off `s3.are_local_buckets`
> (which disables SSL in the default starter compose template).

Disabling `s3.are_local_buckets` also switches to the subdomain style URLs for
the buckets. However, not all S3 providers support these. In particular, MinIO
does not work with these in default configuration. So in such cases you'll also
need to enable `s3.use_path_style_urls`.

## Summary

Set the S3 bucket `endpoint` in `credentials.yaml` to a `yourserverip:3200` or
some such IP / hostname that is accessible from both where you are running the
Ente clients (e.g. the mobile app) and also from within the Docker compose
cluster.