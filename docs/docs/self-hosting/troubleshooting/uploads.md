---
title: Uploads
description: Fixing upload errors when trying to self host Ente
---

# Troubleshooting upload failures

Here are some errors our community members frequently encountered with the
context and potential fixes.

Fundamentally in most situations, the problem is because of minor mistakes or
misconfiguration. Please make sure to reverse proxy museum and MinIO API
endpoint to a domain and check your S3 credentials and whole configuration file
for any minor misconfigurations.

It is also suggested that the user setups bucket CORS or global CORS on MinIO or
any external S3 service provider they are connecting to. To setup bucket CORS,
please [read this](/self-hosting/troubleshooting/bucket-cors).

## What is S3 and how is it incorporated in Ente ?

S3 is an cloud storage protocol made by Amazon (specifically AWS). S3 is
designed to store files and data as objects inside buckets and it is mostly used
for online backups and storing different types of files.

Ente's Docker setup is shipped with [MinIO](https://min.io/) as its default S3
provider. MinIO supports the Amazon S3 protocol and leverages your disk storage
to dump all the uploaded files as encrypted object blobs.

## 403 Forbidden

If museum is able to make a network connection to your S3 bucket but uploads are
still failing, it could be a credentials or permissions issue.

A telltale sign of this is that in the museum logs you can see `403 Forbidden`
errors about it not able to find the size of a file even though the
corresponding object exists in the S3 bucket.

This could be because

1.  The bucket CORS rules do not allow museum to access these objects. For
    uploading files from the browser, you will need to set `allowedOrigins` to
    `*`, and allow the `X-Auth-Token`, `X-Client-Package`, `X-Client-Version`
    headers configuration too.
    [Here is an example of a working configuration](https://github.com/ente-io/ente/discussions/1764#discussioncomment-9478204).

2.  The credentials are not being picked up (you might be setting the correct
    credentials, but not in the place where museum reads them from).

## Mismatch in file size

The "Mismatch in file size" error mostly occurs in a situation where the client
is re-uploading a file which is already in the bucket with a different file
size. The reason for re-upload could be anything including network issue, sudden
killing of app before the upload is complete and etc.
