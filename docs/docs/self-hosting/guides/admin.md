---
title: Server admin
description: Administering your custom self-hosted Ente instance using the CLI
---

## Becoming an admin

By default, the first user (and only the first user) created on the system is
considered as an admin.

This facility is provided as a convenience for people who are getting started
with self hosting. For more serious deployments, we recommend creating an
explicit whitelist of admins.

> [!NOTE]
>
> The first user is only treated as the admin if the list of admins in the
> configuration is empty.
>
> Also, if at some point you delete the first user, then you will need to define
> a whitelist to make some other user as the admin if you wish (since the first
> account has been deleted).

To whitelist the user IDs that can perform admin actions on the server, use the
following steps:

- Create a `museum.yaml` in the directory where you're starting museum from. For
  example, if you're running using `docker compose up`, then this file should be
  in the same directory as `compose.yaml` (generally, `server/museum.yaml`).

    > Docker might've created an empty `museum.yaml` _directory_ on your machine
    > previously. If so, delete that empty directory and create a new file named
    > `museum.yaml`.

- In this `museum.yaml` we can add overrides over the default configuration.

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

# Administering your custom server

> [!NOTE] For the first user (admin) to perform administrative actions using the
> CLI, their userID must be whitelisted in the `museum.yaml` configuration file
> under `internal.admins`. While the first user is automatically granted admin
> privileges on the server, this additional step is required for CLI operations.

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

> [!NOTE]
>
> The CLI command to add an account does not create Ente accounts. It only adds
> existing accounts to the list of (existing) accounts that the CLI can use.

## Backups

See this [document](/self-hosting/administration/backup).
