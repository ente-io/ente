---
title: Configuring your server
description: Guide to writing a museum.yaml
---

# Configuring your server

Ente's monolithic server is called **museum**.

`museum.yaml` is a YAML configuration file used to configure museum. By default,
[`local.yaml`](https://github.com/ente-io/ente/tree/main/server/configurations/local.yaml)
is provided, but its settings are overridden with those from `museum.yaml`.

If you used our quickstart script, your `my-ente` directory will include a
`museum.yaml` file with preset configurations for encryption keys, secrets,
PostgreSQL and MinIO.

> [!TIP]
>
> Always do `docker compose down` inside your `my-ente` directory. If you've
> made changes to `museum.yaml`, restart the containers with
> `docker compose up -d ` to see your changes in action.

## S3 buckets

The `s3` section within `museum.yaml` is by default configured to use local
MinIO buckets.

If you wish to use an external S3 provider, you can edit the configuration with
your provider's credentials, and set `are_local_buckets` to `false`.

Check out [Configuring S3] to understand
more about configuring S3 buckets.

MinIO uses the port `3200` for API Endpoints and their web app runs over
`:3201`. You can login to MinIO Web Console by opening `localhost:3201` in your
browser.

If you face any issues related to uploads then checkout
[Troubleshooting bucket CORS](/self-hosting/troubleshooting/bucket-cors) and
[Frequently encountered S3 errors].

## Web apps

The web apps for Ente Photos is divided into multiple sub-apps like albums,
cast, auth, etc. These endpoints are configurable in `museum.yaml` under the
`apps.*` section.

For example,

```yaml
apps:
    public-albums: https://albums.myente.xyz
    cast: https://cast.myente.xyz
    accounts: https://accounts.myente.xyz
```

> [!IMPORTANT] By default, all the values redirect to our publicly hosted
> production services. For example, if `public-albums` is not configured your
> shared album will use the `albums.ente.io` URL.

After you are done with filling the values, restart museum and the app will
start utilizing those endpoints instead of Ente's production instances.

Once you have configured all the necessary endpoints, `cd` into `my-ente` and
stop all the Docker containers with `docker compose down` and restart them with
`docker compose up -d`.

Similarly, you can use the default
[`local.yaml`](https://github.com/ente-io/ente/tree/main/server/configurations/local.yaml)
as a reference for building a functioning `museum.yaml` for many other
functionalities like SMTP, Hardcoded-OTTs, etc.