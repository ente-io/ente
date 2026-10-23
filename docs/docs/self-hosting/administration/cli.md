---
title: Ente CLI for Self-hosted Instance - Self-hosting
description: Guide to configuring Ente CLI for Self Hosted Instance
---

# Ente CLI for self-hosted instance

Use Ente CLI to export data and administer your own server. These instructions use the new CLI introduced with `ente-cli-v0.4.0`. For the previous Go CLI, read the [migration guide](/cli/migration) before switching; the new CLI does not read its configuration or saved credentials.

## Step 1: Install the CLI

Follow [Install Ente CLI](/cli/install) for your platform.

## Step 2: Whitelist admins

Whitelist your administrator account using [Whitelist admins](/self-hosting/administration/users#whitelist-admins).

## Step 3: Log in to your server

Pass your Museum API endpoint at login. The CLI saves it with the account and uses it for subsequent commands:

```sh
ente account login --account home-server --app photos --host https://api.example.org
```

Use an existing verified account. The new CLI also supports [account creation](/cli/accounts#create-an-account). Each app needs its own login; use `--app auth` for Auth exports.

See [Accounts](/cli/accounts#use-a-self-hosted-server) for multiple accounts and headless setup, and [Photos](/cli/photos) for exports.

## Step 4: Change storage and account validity

For a user on a free subscription:

```sh
ente admin user update-subscription user@example.com --no-limit --account home-server

# Set explicit limits instead
ente admin user update-subscription user@example.com --storage 500GB --expires 2027-12-31 --account home-server
```

`--no-limit` sets 100 TB of storage and an expiry 100 years from now, rather than literal unlimited storage. An omitted storage or expiry value stays unchanged. Paid plans are rejected. The command shows the proposed change and asks for confirmation.

The administrator must be whitelisted and the target user must be registered and verified on the same server.

## Other administrative tasks

See [Administration](/cli/admin) for listing users, resetting login factors, deleting users, testing email, and running changes unattended. See [Migration](/cli/migration#administrator-commands) for replacements for previous administrative commands.
