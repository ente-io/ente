## Self Hosting

If you are self-hosting the server, you can still configure CLI to export data & perform basic admin actions.

To do this, first configure the CLI to point to your server. Define a `config.yaml` and put it in `~/.ente/` or the directory specified by `ENTE_CLI_CONFIG_DIR`.

`ENTE_CLI_CONFIG_DIR` selects both configuration and the saved account database. The legacy `ENTE_CLI_CONFIG_PATH` is used only when `ENTE_CLI_CONFIG_DIR` is unset. For example, use `ENTE_CLI_CONFIG_DIR=/path/to/existing-cli-directory ente export` when that directory already contains the accounts you intend to use.

If you previously kept configuration in the working directory, migrate its settings into the existing configuration directory, then remove or rename the old file. Network commands stop while a separate working-directory config exists; local account commands remain available. Selecting a different directory, including `.`, also selects a different account database. Invalid trusted configuration must be corrected before running commands.

```yaml
endpoint:
  api: "http://localhost:8080"
```

You should be able to [add an account](https://github.com/ente/ente/blob/main/cli/docs/generated/ente_account_add.md), and subsequently increase the [storage and account validity](https://github.com/ente/ente/blob/main/cli/docs/generated/ente_admin_update-subscription.md) using the CLI.

For the admin actions, you first need to whitelist admin users. You can create `server/museum.yaml`, and whitelist add the admin userID `internal.admins`. See [local.yaml](https://github.com/ente/ente/blob/main/server/configurations/local.yaml#L211C1-L232C1) in the server source code for details about how to define this.

You can use [account list](https://github.com/ente/ente/blob/main/cli/docs/generated/ente_account_list.md) command to find the user id of any account.

```yaml
# ....

internal:
  admins:
    # - 1580559962386440

# ....
```
