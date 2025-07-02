---
title: Configuring S3 buckets
description:
    Configure S3 endpoints to fix upload errors or use your self hosted ente
    from outside localhost
---

# Architecture

![Client, Museum, S3](/client-museum-s3.png)

There are three components involved in uploading a file:

1.  The client (e.g. the web app or the mobile app)
2.  Ente's server (museum)
3.  The S3-compatible object storage (e.g. MinIO in the default starter)

For the uploads to work, all three of them need to be able to reach each other.
This is because the client uploads directly to the object storage.

A file upload flows as follows:

1.  Client that wants to upload a file asks museum where it should upload the
    file to
2.  museum creates pre-signed URLs for the S3 bucket that was configured
3.  Client directly uploads to the S3 buckets these URLs
4.  Client finally informs museum that a file has been uploaded to this URL

The upshot of this is that _both_ the client and museum should be able to reach
your S3 bucket.

## Configuring S3

The URL for the S3 bucket is configured in
[scripts/compose/credentials.yaml](https://github.com/ente-io/ente/blob/main/server/scripts/compose/credentials.yaml#L10).

You can edit this file directly while testing, though it is more robust to
create a `museum.yaml` (in the same folder as the Docker compose file) and to
setup your custom configuration there.

> [!TIP] For more details about these configuration objects, see the
> documentation for the `s3` object in
> [configurations/local.yaml](https://github.com/ente-io/ente/blob/main/server/configurations/local.yaml).

By default, you only need to configure the endpoint for the first bucket.

The Docker compose file is shipped with MinIO as the self hosted S3 compatible
storage. By default, MinIO server is served on `localhost:3200` and the MinIO UI
on `localhost:3201`.

For example, in a localhost network situation, the way this connection works is,
museum (`1`) and MinIO (`2`) run on the same Docker network and the web app
(`3`) will also be hosted on your localhost. This enables all the three
components of the setup to communicate with each other seamlessly.

The same principle applies if you're deploying to your custom domain.

## Replication

![Replication](/replication.png)

<p align="center">Community contributed diagram of Ente's replication process</p>

> [!IMPORTANT]
>
> As of now, replication works only if all the 3 storage type needs are
> fulfilled (1 hot, 1 cold and 1 glacier storage).
>
> [Reference](https://github.com/ente-io/ente/discussions/3167#discussioncomment-10585970)

If you're wondering why there are 3 buckets on the MinIO UI - that's because our
production instance uses these to perform
[replication](https://ente.io/reliability/).

If you're also wondering about why the bucket names are specifically what they
are, it's because that is exactly what we are using on our production instance.
We use `b2-eu-cen` as hot, `wasabi-eu-central-2-v3` as cold (also the secondary
hot) and `scw-eu-fr-v3` as glacier storage. As of now, all of this is hardcoded.
Hence, the same hardcoded configuration is applied when you self host Ente.

In a self hosted Ente instance replication is turned off by default. When
replication is turned off, only the first bucket (`b2-eu-cen`) is used, and the
other two are ignored. Only the names here are specifically fixed, but in the
configuration body you can put any other keys. It does not have any relation
with `b2`, `wasabi` or even `scaleway`.

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

### Example

An example `museum.yaml` when you're trying to connect to museum running on your
computer from your phone on the same WiFi network:

```yaml
s3:
    are_local_buckets: true
    b2-eu-cen:
        key: test
        secret: testtest
        endpoint: http://<YOUR-WIFI-IP>:3200
        region: eu-central-2
        bucket: b2-eu-cen
```
