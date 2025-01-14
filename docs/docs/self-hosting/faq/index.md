---
title: FAQ - Self hosting
description: Frequently asked questions about self hosting Ente
---

# Frequently Asked Questions

### Do Ente Photos and Ente Auth share the same backend?

Yes. The apps share the same backend, the same database and the same object
storage namespace. The same user account works for both of them.

### Can I just self host Ente Auth?

Yes, if you wish, you can self-host the server and use it only for the 2FA auth
app. The starter Docker compose will work fine for either Photos or Auth (or
both!).

> You currently don't need to configure the S3 object storage (e.g. minio
> containers) if you're only using your self hosted Ente instance for auth.

### Can I use the server with _X_ as the object storage?

Yes. As long as whatever X you're using provides an S3 compatible API, you can
use it as the underlying object storage. For example, the starter self-hosting
Docker compose file we offer uses MinIO, and on our production deployments we
use Backblaze/Wasabi/Scaleway. But that's not the full list - as long as the
service you intend to use has a S3 compatible API, it can be used.

### How do I increase storage space for users on my self hosted instance?

See the [guide for administering your server](/self-hosting/guides/admin). In
particular, you can use the `ente admin update-subscription` CLI command to
increase the
[storage and account validity](https://github.com/ente-io/ente/blob/main/cli/docs/generated/ente_admin_update-subscription.md)
of accounts on your instance.

### How can I become an admin on my self hosted instance?

The first user you create on your instance is treated as an admin.

If you want, you can modify this behaviour by providing an explicit list of
admins in the [configuration](/self-hosting/guides/admin#becoming-an-admin).

### Can I disable registration of new accounts on my self hosted instance?

Yes. See `internal.disable-registration` in local.yaml.
