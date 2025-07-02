---
title: Bucket CORS
description: Troubleshooting CORS issues with S3 Buckets
---

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

## For Self-hosted Minio Instance

::: warning

- MinIO does not support bucket CORS in the community edition which is used by
  default. For more information, check
  [this discussion](https://github.com/minio/minio/discussions/20841). However,
  global CORS configuration is possible.
- MinIO does not take JSON CORS file as the input, instead you will have to
  build a CORS.xml file or just convert the above `cors.json` to XML.

:::

A minor requirement here is the tool `mc` for managing buckets via command line
interface. Checkout the `mc set alias` document to configure alias for your
instance and bucket. After this you will be prompted for your AccessKey and
Secret, which is your username and password.

```sh
mc cors set <your-minio>/<your-bucket-name /path/to/cors.xml
```

or, if you just want to just set the `AllowedOrigins` Header, you can use the
following command to do so.

```sh
mc admin config set <your-minio>/<your-bucket-name> api cors_allow_origin="*"
```

You can create also `.csv` file and dump the list of origins you would like to
allow and replace the `*` with `path` to the CSV file.

Now, uploads should be working fine.
