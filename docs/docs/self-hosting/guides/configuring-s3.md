---
title: Configuring S3 buckets
description:
    Configure S3 endpoints to fix upload errors or use your self hosted ente
    from outside localhost
---

# Components of the Architecture

![Client, Museum, S3](/client-museum-s3.png)

There are three components involved in uploading:

1.  The client (e.g. the web app or the mobile app)
2.  Ente's server (museum)
3.  The S3-compatible object storage (e.g. minio in the default starter)

For the uploads to work, all three of them need to be able to reach each other.
This is because the client uploads directly to the object storage. The
interaction goes something like this:

1.  Client wants to upload, it asks museum where it should upload to.
2.  Museum creates pre-signed URLs for the S3 bucket that was configured.
3.  Client directly uploads to the S3 buckets these URLs.

The upshot of this is that _both_ the client and museum should be able to reach
your S3 bucket.

## Configuring S3 

The URL for the S3 bucket is configured in
[scripts/compose/credentials.yaml](https://github.com/ente-io/ente/blob/main/server/scripts/compose/credentials.yaml#L10).
You can edit this file directly when testing, though it is just simpler and more
robust to create a `museum.yaml` (in the same folder as the Docker compose file)
and put your custom configuration there (in your case, you can put an entire
`s3` config object in your `museum.yaml`).

> [!TIP]
> For more details about these configuration objects, see the documentation for
> the `s3` object in
> [configurations/local.yaml](https://github.com/ente-io/ente/blob/main/server/configurations/local.yaml).

By default, you only need to configure the endpoint for the first bucket.

The docker compose file is shipped with MinIO as the Self Hosted S3 Compatible Storage. 
By default, MinIO server is served on `localhost:3200` and the MinIO UI on 
`localhost:3201`. 
For example, in a localhost network situation, the way this 
connection works is, Museum (`1`) and MinIO (`2`) run on the same docker network and 
the web app (`3`) which will also be hosted on the localhost. This enables all the 
three components of the setup being able to communicate with each other seamlessly.

The same principle applies if you're deploying to your custom domain.

## Replication 

If you're wondering why there are 3 buckets on MinIO UI - that's because our 
production instance uses these to perform [replication](https://ente.io/reliability/).

In a self hosted Ente Instance replication is turned off by default.
When replication is turned off, only the first bucket (`b2-eu-cen`) is used, 
and you can ignore the other two. Use the `s3.hot_storage.primary` option 
if you'd like to set one of the other predefined buckets as the primary bucket.

> [!IMPORTANT]
> As of now, Replication works only if all the 3 storage type 
> needs are fulfilled (1 Hot, 1 Cold and 1 Glacier Storage).
>
> [Reference](https://github.com/ente-io/ente/discussions/3167#discussioncomment-10585970)

## SSL Configuration 

> [!NOTE]
>
> If you need to configure SSL, for example if you're running over the internet,
> you'll need to turn off `s3.are_local_buckets` (which disables SSL in the
> default starter compose template).
>

Disabling `s3.are_local_buckets` also switches to the subdomain style URLs for
the buckets. However, not all S3 providers support these, in particular, minio
does not work with these in default configuration. So in such cases you'll
also need to then enable `s3.use_path_style_urls`.

## Summary

Set the S3 bucket `endpoint` in `credentials.yaml` to a `yourserverip:3200` or
some such IP/hostname that accessible from both where you are running the Ente
clients (e.g. the mobile app) and also from within the Docker compose cluster.

#### Example

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

## FAE (Frequently Answered Errors)

Here are some Frequently Answered Errors from the Community Chat with the reasoning
for a particular error and its potential fix. 

In most situations, the problem turns out to be some minute mistakes or misconfigurations 
on the users end and that turns out to be the bottleneck of the whole problem. 
Please make sure to `reverse_proxy` Museum to a domain as well as check your S3 
Credentials and whole config for any minor mis-configurations.

It is also suggested that the user setups Bucket CORS on MinIO or any external
S3 Bucket they are connecting to. To setup Bucket CORS, help yourself by upload
[this](https://help.ente.io/self-hosting/guides/external-s3#_5-fix-potential-cors-issue-with-your-bucket).

### 403 Forbidden

If museum (`2`) is able to make a network connection to your S3 bucket (`3`) but
uploads are still failing, it could be a credentials or permissions issue. A
telltale sign of this is that in the museum logs you can see `403 Forbidden`
errors about it not able to find the size of a file even though the
corresponding object exists in the S3 bucket.

To fix these, you should ensure the following:

1.  The bucket CORS rules do not allow museum to access these objects.
    - For uploading files from the browser, you will need to currently set
    allowedOrigins to "\*", and allow the "X-Auth-Token", "X-Client-Package"
    headers configuration too.
    [Here is an example of a working configuration](https://github.com/ente-io/ente/discussions/1764#discussioncomment-9478204).

2.  The credentials are not being picked up (you might be setting the correct
    creds, but not in the place where museum picks them from).

### Mismatch in File Size 

The "Mismatch in File Size" error mostly occurs in a situation where the client (`1`) 
is re-uploading a file which is already in the bucket with a different File Size. The 
reason for re-upload could be anything including Network issue, sudden killing of app
before the upload is complete and etc. 

This is also one of Museums (`2`) Validation Checks for the size of file being 
re-uploaded from the client to the size of the file which is already 
uploaded to the S3 Bucket.

In most case, it is very unlikely that this error could be a cause of some mistake in 
the configuration or Browser/Bucket CORS.
