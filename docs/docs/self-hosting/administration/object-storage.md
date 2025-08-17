---
title: Configuring Object Storage - Self-hosting
description:
    Configure Object Storage for storing files along with some troubleshooting
    tips
---

# Configuring Object Storage

Ente relies on [S3-compatible](https://docs.aws.amazon.com/s3/) cloud storage
for storing files (photos, thumbnails and videos) as objects.

Ente ships MinIO as S3-compatible storage by default in quickstart and Docker
Compose for quick testing.

This document outlines configuration of S3 buckets and enabling replication for
further usage.

## Museum

The S3-compatible buckets have to be configured in `museum.yaml` file.

### General Configuration

Some of the common configuration that can be done at top-level are:

1. **SSL Configuration:** If you need to configure SSL (i. e., the buckets are
   accessible via HTTPS), you'll need to set `s3.are_local_buckets` to `false`.
2. **Path-style URLs:** Disabling `s3.are_local_buckets` also switches to the
   subdomain-style URLs for the buckets. However, some S3 providers such as
   MinIO do not support this.

    Set `s3.use_path_style_urls` to `true` for such cases.

### Replication

> [!IMPORTANT]
>
> Replication works only if all 3 storage buckets are configured (2 hot and 1
> cold storage).
>
> For more information, check
> [this discussion](https://github.com/ente-io/ente/discussions/3167#discussioncomment-10585970)
> and our article on ensuring [reliability](https://ente.io/reliability/).

Replication is disabled by default in self-hosted instance. Only the first
bucket (`b2-eu-cen`) is used.

Only the names are specifically fixed, you can put any other keys in
configuration body.

Use the `s3.hot_storage.primary` option if you'd like to set one of the other
pre-defined buckets as the primary bucket.

### Bucket configuration

The keys `b2-eu-cen` (primary storage), `wasabi-eu-central-2-v3` (secondary
storage) and `scw-eu-fr-v3` (cold storage) are hardcoded, however, the keys and
secret can be anything.

It has no relation to Backblaze, Wasabi or Scaleway.

Each bucket's endpoint, region, key and secret should be configured accordingly
if using an external bucket.

If a bucket has SSL support enabled, set `s3.are_local_buckets` to `false`. Enable path-style URL by setting `s3.use_path_style_urls` to `true`.

::: note

You can configure this for individual buckets over defining top-level configuration if you are using the latest server image (August 2025)

:::

A sample configuration for `b2-eu-cen` is provided, which can be used for other 2 buckets as well:

```yaml
b2-eu-cen:
    are_local_buckets: true
    use_path_style_urls: true
    key: <key>
    secret: <secret>
    endpoint: localhost:3200
    region: eu-central-2
    bucket: b2-eu-cen
```

## CORS (Cross-Origin Resource Sharing)

If you cannot upload a photo due to CORS error, you need to fix the CORS
configuration of your bucket.

Use the content provided below for creating a `cors.json` file:

```json
{
    "CORSRules": [
        {
            "AllowedOrigins": ["*"],
            "AllowedHeaders": ["*"],
            "AllowedMethods": ["GET", "HEAD", "POST", "PUT", "DELETE"],
            "MaxAgeSeconds": 3000,
            "ExposeHeaders": ["Etag"]
        }
    ]
}
```

You may have to change the `AllowedOrigins` to allow only certain origins (your
Ente web apps and Museum) for security.

Assuming you have AWS CLI on your system and that you have configured it with
your access key and secret, you can execute the below command to set bucket
CORS. Make sure to enter the right path for the `cors.json` file.

```shell
aws s3api put-bucket-cors --bucket YOUR_S3_BUCKET --cors-configuration /path/to/cors.json
```

### MinIO

Assuming you have configured an alias for MinIO account using the command:

```shell
mc alias set storage-account-alias minio-endpoint minio-key minio-secret
```

where,

1. `storage-account-alias` is a valid storage account alias name
2. `minio-endpoint` is the endpoint where MinIO is being served without the
   protocol (http or https). Example: `localhost:3200`
3. `minio-key` is the MinIO username defined in `MINIO_ROOT_USER`
4. `minio-secret` is the MinIO password defined in `MINIO_PASSWORD`

To set the `AllowedOrigins` Header, you can use the following command:.

```shell
mc admin config set storage-account-alias api cors_allow_origin="*"
```

You can create also `.csv` file and dump the list of origins you would like to
allow and replace the `*` with path to the CSV file.
