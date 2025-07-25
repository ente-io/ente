---
title: Configuring Object Storage
description:
    Configure Object Storage for storing files along with some troubleshooting tips
---

# Configuring Object Storage

## Replication

> [!IMPORTANT]
>
> As of now, replication works only if all the 3 storage buckets are configured (2 hot and 1 cold storage).
>
> For more information, check this
> [discussion](https://github.com/ente-io/ente/discussions/3167#discussioncomment-10585970)
> and our article on ensuring [reliability](https://ente.io/reliability/).

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

# Fix potential CORS issues with your Buckets

## For AWS S3

If you cannot upload a photo due to a CORS issue, you need to fix the CORS
configuration of your bucket.

Create a `cors.json` file with the following content:

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

You may want to change the `AllowedOrigins` to a more restrictive value.

If you are using AWS for S3, you can execute the below command to get rid of
CORS. Make sure to enter the right path for the `cors.json` file.

```bash
aws s3api put-bucket-cors --bucket YOUR_S3_BUCKET --cors-configuration /path/to/cors.json
```

## For MinIO

Checkout the `mc set alias` document to configure alias for your
instance and bucket. After this you will be prompted for your AccessKey and
Secret, which is your username and password.

To set the `AllowedOrigins` Header, you can use the
following command to do so.

```sh
mc admin config set <your-minio>/<your-bucket-name> api cors_allow_origin="*"
```

You can create also `.csv` file and dump the list of origins you would like to
allow and replace the `*` with `path` to the CSV file.
