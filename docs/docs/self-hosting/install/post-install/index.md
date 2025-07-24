---
title: Post-installation steps - Self-hosting
description: Steps to be followed post-installation for smooth experience
---

# Post-installation Steps

A list of steps that should be done after installing Ente are described below:

## Step 1: Creating first user

The first user to be created will be treated as an admin user.

Once Ente is up and running, the Ente Photos web app will be accessible on
`http://localhost:3000`. Open this URL in your browser and proceed with creating
an account.

To complete your account registration you will need to enter a 6-digit
verification code.

This code can be found in the server logs, which should already be shown in your
quickstart terminal. Alternatively, you can open the server logs with the
following command from inside the `my-ente` folder:

```sh
sudo docker compose logs
```

![otp](/otp.png)

## Step 2: Configure apps to use your server

You can modify various Ente client apps and CLI to connect to a self hosted
custom server endpoint.

### Mobile

The pre-built Ente apps from GitHub / App Store / Play Store / F-Droid can be
easily configured to use a custom server.

You can tap 7 times on the onboarding screen to bring up a page where you can
configure the endpoint the app should be connecting to.

![Setting a custom server on the onboarding screen](custom-server.png)

### Desktop and web

Same as the mobile app, you can tap 7 times on the onboarding screen to
configure the endpoint the app should connect to.

<div align="center">

![Setting a custom server on the onboarding screen on desktop or self-hosted web
apps](web-dev-settings.png){width=400px}

</div>

This works on both the desktop app and web app (if you deploy on your own).

To make it easier to identify when a custom server is being used, app will
thereafter show the endpoint in use (if not Ente's production server) at the
bottom of the login prompt:

![Custom server indicator on the onboarding screen](web-custom-endpoint-indicator.png)

Similarly, it'll be shown at other screens during the login flow. After login,
you can also see it at the bottom of the sidebar.

Note that the custom server configured this way is cleared when you reset the
state during logout. In particular, the app also does a reset when you press the
change email button during the login flow.

## Step 3: Configure Ente CLI

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