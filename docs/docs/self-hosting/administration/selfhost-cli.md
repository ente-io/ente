---
title: CLI for Self Hosted Instance
description: Guide to configuring Ente CLI for Self Hosted Instance
---

# Ente CLI for self-hosted instance

If you are self-hosting, you can configure CLI to export data &
perform basic administrative actions.

## Step 1: Configure endpoint

To do this, first configure the CLI to use your server's endpoint.

Define `config.yaml` and place it in `~/.ente/` directory or directory
specified by `ENTE_CLI_CONFIG_DIR` or CLI's directory.

``` yaml
endpoint:
    api: http://localhost:8080
```

You should be able to
[add an account](https://github.com/ente-io/ente/blob/main/cli/docs/generated/ente_account_add.md),
and subsequently increase the
[storage and account validity](https://github.com/ente-io/ente/blob/main/cli/docs/generated/ente_admin_update-subscription.md)
using the CLI.

For administrative actions, you first need to whitelist admin users.
You can create `server/museum.yaml`, and whitelist add the admin user ID `internal.admins`. See
[local.yaml](https://github.com/ente-io/ente/blob/main/server/configurations/local.yaml#L211C1-L232C1)
in the server source code for details about how to define this.

You can use
[account list](https://github.com/ente-io/ente/blob/main/cli/docs/generated/ente_account_list.md)
command to find the user id of any account.

```yaml
internal:
    admins:
        - 1580559962386440
```
