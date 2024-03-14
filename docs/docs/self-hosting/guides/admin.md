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

For the admin actions, you can create `server/museum.yaml`, and whitelist add
the admin userID `internal.admins`. See
[local.yaml](https://github.com/ente-io/ente/blob/main/server/configurations/local.yaml#L211C1-L232C1)
in the server source code for details about how to define this.

```yaml
....
internal:
  admins:
    # - 1580559962386440

....
```

You can use
[account list](https://github.com/ente-io/ente/blob/main/cli/docs/generated/ente_account_list.md)
command to find the user id of any account.
