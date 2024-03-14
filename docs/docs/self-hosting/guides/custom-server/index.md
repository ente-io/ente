---
title: Custom server
description: Using a custom self-hosted server with frontend apps
---

# Custom server for mobile apps

The pre-built Ente apps from GitHub / App Store / Play Store / F-Droid can be
easily configured to use a custom server.

You can tap 7 times on the onboarding screen to bring up a page where you can
configure the endpoint the app should be connecting to.

![Setting a custom server on the onboarding screen](custom-server.png)

> [!IMPORTANT]
>
> This is only supported by the Ente Auth app currently. We'll add this same
> functionality to the Ente Photos app soon.

---

# CLI

> [!WARNING] The new version of CLI that supports connecting to custom server is
> still in beta. You can download the beta version from
> [here](https://github.com/ente-io/ente/releases?q=tag%3Acli-v0)

Define a config.yaml and put it either in the same directory as CLI or path
defined in env variable `ENTE_CLI_CONFIG_PATH`

```yaml
endpoint:
    api: "http://localhost:8080"
```

You should be able to
[add an account](https://github.com/ente-io/ente/blob/main/cli/docs/generated/ente_account_add.md),
and subsequently increase the
[storage and account validity](https://github.com/ente-io/ente/blob/main/cli/docs/generated/ente_admin_update-subscription.md)
using the CLI.

For the admin actions, you can create `server/museum.yaml`, and whitelist add
the admin userID `internal.admins`. See
[local.yaml](https://github.com/ente-io/ente/blob/main/server/configurations/local.yaml#L211C1-L232C1)
in the server source code for details about how to define this.

You can use
[account list](https://github.com/ente-io/ente/blob/main/cli/docs/generated/ente_account_list.md)
command to find the user id of any account.

```yaml
....
internal:
  admins:
    # - 1580559962386440

....
```
