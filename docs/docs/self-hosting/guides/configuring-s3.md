---
title: Configuring S3 buckets
description:
    Configure S3 endpoints to fix upload errors or use your self hosted ente
    from outside localhost
---

# Configuring S3

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

The URL for the S3 bucket is configured in
[scripts/compose/credentials.yaml](https://github.com/ente-io/ente/blob/main/server/scripts/compose/credentials.yaml#L10).
You can edit this file directly when testing, though it is just simpler and more
robust to create a `museum.yaml` (in the same folder as the Docker compose file)
and put your custom configuration there (in your case, you can put an entire
`s3` config object in your `museum.yaml`).

> [!TIP]
>
> For more details about these configuration objects, see the documentaion for
> the `s3` object in
> [configurations/local.yaml](https://github.com/ente-io/ente/blob/main/server/configurations/local.yaml).

By default, you only need to configure the endpoint for the first bucket.

> [!NOTE]
>
> If you're wondering why there are 3 buckets - that's because our production
> instance uses these to perform replication.
>
> However, in a self hosted setup replication is off by default (you can turn it
> on if you want). When replication is turned off, only the first bucket (it
> must be named `b2-eu-cen`) is used, and you can ignore the other two. Use the
> `hot_bucket` option if you'd like to set one of the other predefined buckets
> as the "first" bucket.

The `endpoint` for the first bucket in the starter `credentials.yaml` is
`localhost:3200`. The way this works then is that both museum (`2`) and minio
(`3`) are running within the same Docker compose cluster, so are able to reach
each other. If at this point we were to run the web app (`1`) on localhost (say
using `yarn dev:photos`), it would also run on localhost and thus would be able
to reach `3`.

If you were to try and connect from a mobile app, this would not work since
`localhost:3200` would not resolve on your mobile. So you'll need to modify this
endpoint to a value, say `yourserverip:3200`, so that the mobile app can also
reach it.

The same principle applies if you're deploying to your custom domain.

> [!NOTE]
>
> If you need to configure SSL, for example if you're running over the internet,
> you'll need to turn off `s3.are_local_buckets` (which disables SSL in the
> default starter compose template).
>
> Disabling `s3.are_local_buckets` also switches to the subdomain style URLs for
> the buckets. However, not all S3 providers support these, in particular, minio
> does not work with these in default configuration. So in such cases you'll
> also need to then enable `s3.use_path_style_urls`.

To summarize:

Set the S3 bucket `endpoint` in `credentials.yaml` to a `yourserverip:3200` or
some such IP/hostname that accessible from both where you are running the Ente
clients (e.g. the mobile app) and also from within the Docker compose cluster.

### 403 Forbidden

If museum (`2`) is able to make a network connection to your S3 bucket (`3`) but
uploads are still failing, it could be a credentials or permissions issue. A
telltale sign of this is that in the museum logs you can see `403 Forbidden`
errors about it not able to find the size of a file even though the
corresponding object exists in the S3 bucket.

To fix these, you should ensure the following:

1.  The bucket CORS rules do not allow museum to access these objects.

    > For uploading files from the browser, you will need to currently set
    > allowedOrigins to "\*", and allow the "X-Auth-Token", "X-Client-Package"
    > headers configuration too.
    > [Here is an example of a working configuration](https://github.com/ente-io/ente/discussions/1764#discussioncomment-9478204).

2.  The credentials are not being picked up (you might be setting the correct
    creds, but not in the place where museum picks them from).
