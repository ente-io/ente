---
title: Verification code
description: Getting the OTP for a self hosted Ente
---

# Verification code

The self-hosted Ente by default does not send out emails, so you can pick the
verification code by:

- Getting it from the server logs, or

- Reading it from the DB (otts table)

The easiest option when getting started is to look for it in the server (museum)
logs. If you're already running the docker compose cluster using the quickstart
script, you should be already seeing the logs in your terminal. Otherwise you
can go to the folder (e.g. `my-ente`) where your `compose.yaml` is, then run
`docker compose logs museum --follow`. Once you can see the logs, look for a
line like:

```
... Skipping sending email to email@example.com: *Verification code: 112089*
```

That is the verification code.

> [!TIP]
>
> You can also configure your instance to send out emails so that you can get
> your verification code via emails by using the `smtp` section in the config.

You can also set pre-defined hardcoded OTTs for certain users when running
locally by creating a `museum.yaml` and adding the `internal.hardcoded-ott`
configuration setting to it. See
[local.yaml](https://github.com/ente-io/ente/blob/main/server/configurations/local.yaml)
in the server source code for details about how to define this.

> [!NOTE]
>
> If you're not able to get the OTP with the above methods, make sure that you
> are actually connecting to your self hosted instance and not to Ente's
> production servers. e.g. you can use the network requests tab in the browser
> console to verify that the API requests are going to your server instead of
> `api.ente.io`.
