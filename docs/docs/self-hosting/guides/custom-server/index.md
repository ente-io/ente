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

## CLI

> [!NOTE]
>
> You can download the CLI from
> [here](https://github.com/ente-io/ente/releases?q=tag%3Acli-v0)

Define a config.yaml and put it either in the same directory as where you run
the CLI from ("current working directory"), or in the path defined in env
variable `ENTE_CLI_CONFIG_PATH`:

```yaml
endpoint:
    api: "http://localhost:8080"
```

(Another
[example](https://github.com/ente-io/ente/blob/main/cli/config.yaml.example))

## Web apps and Photos desktop app

You will need to build the app from source and use the
`NEXT_PUBLIC_ENTE_ENDPOINT` environment variable to tell it which server to
connect to. For example:

```sh
NEXT_PUBLIC_ENTE_ENDPOINT=http://localhost:8080 yarn dev:photos
```

For more details, see
[hosting the web app](https://help.ente.io/self-hosting/guides/web-app).
