---
title: Server admin
description: Administering your custom self-hosted Ente instance using the CLI
---

# Administering your custom server

You can use
[Ente's CLI](https://github.com/ente-io/ente/releases?q=tag%3Acli-v0) to
administer your self hosted server.

First we need to get your CLI to connect to your custom server. Define a
config.yaml and put it either in the same directory as CLI or path defined in
env variable `ENTE_CLI_CONFIG_PATH`

```yaml
endpoint:
    api: "http://localhost:8080"
```

Now you should be able to
[add an account](https://github.com/ente-io/ente/blob/main/cli/docs/generated/ente_account_add.md),
and subsequently increase the
[storage and account validity](https://github.com/ente-io/ente/blob/main/cli/docs/generated/ente_admin_update-subscription.md)
using the CLI.

For security purposes, we need to whitelist the user IDs that can perform admin
actions on the server. To do this,

-   Create a `museum.yaml` in the directory where you're starting museum from.
    For example, if you're running using `docker compose up`, then this file
    should be in the same directory as `compose.yaml` (generally,
    `server/museum.yaml`).

    > Docker might've created an empty `museum.yaml` _directory_ on your machine
    > previously. If so, delete that empty directory and create a new file named
    > `museum.yaml`.

-   In this `museum.yaml` we can add overrides over the default configuration.

For whitelisting the admin userIDs we need to define an `internal.admins`. See
the "internal" section in
[local.yaml](https://github.com/ente-io/ente/blob/main/server/configurations/local.yaml)
in the server source code for details about how to define this.

Here is an example. Suppose we wanted to whitelist a user with ID
`1580559962386440`, we can create the following `museum.yaml`

```yaml
internal:
    admins:
        - 1580559962386440
```

You can use
[account list](https://github.com/ente-io/ente/blob/main/cli/docs/generated/ente_account_list.md)
command to find the user id of any account.
