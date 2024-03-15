---
title: Custom server
description: Using a custom self-hosted server with Ente client apps and CLI
---

# Connecting to a custom server

You can modify various Ente client apps and CLI to connect to a self hosted
custom server endpoint.

## Mobile apps

The pre-built Ente apps from GitHub / App Store / Play Store / F-Droid can be
easily configured to use a custom server.

You can tap 7 times on the onboarding screen to bring up a page where you can
configure the endpoint the app should be connecting to.

![Setting a custom server on the onboarding screen](custom-server.png)

> [!IMPORTANT]
>
> This is only supported by the Ente Auth app currently. We'll add this same
> functionality to the Ente Photos app soon.

## CLI

> [!NOTE]
>
> You can download the CLI from
> [here](https://github.com/ente-io/ente/releases?q=tag%3Acli-v0)

Define a config.yaml and put it either in the same directory as CLI or path
defined in env variable `ENTE_CLI_CONFIG_PATH`

```yaml
endpoint:
    api: "http://localhost:8080"
```
