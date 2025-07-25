---
title: Quickstart - Self-hosting
description: Getting started with self-hosting Ente
---

# Quickstart

If you're looking to spin up Ente on your server for preserving those
sweet memories or using Auth for 2FA codes, you are in the right place!

Our entire source code ([including the server](https://ente.io/blog/open-sourcing-our-server/))
is open source. This is the same code we use on production.

For a quick preview of Ente on your server, make sure your system meets the
requirements mentioned below. After trying the preview, you can explore other
ways of self-hosting Ente on your server as described in the documentation.

## Requirements

- A system with at least 1 GB of RAM and 1 CPU core
- [Docker Compose](https://docs.docker.com/compose/)

> For more details, check out the
> [requirements page](/self-hosting/installation/requirements).

## Set up the server

Run this command on your terminal to setup Ente.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh)"
```

The above command creates a directory `my-ente` in the current working
directory, prompts to start the cluster with needed containers after pulling the images required to run Ente.

![quickstart](/quickstart.png)

> [!NOTE]
> Make sure to modify the default values in `compose.yaml` and `museum.yaml`
> if you wish to change endpoints, bucket configuration or server configuration.

## Try the web app

Open Ente Photos web app at `http://<machine-ip>:3000` (or `http://localhost:3000` if
using on same local machine) and select **Don't have an account?** to create a
new user.

![Onboarding Screen](/onboarding.png)

Follow the prompts to sign up.

![Sign Up Page](/sign-up.png)

You will be prompted to enter verification code. Check the cluster logs using `sudo docker compose logs` and enter the same.

![Verification Code](/otp.png)

Upload a picture via the web user interface.

Alternatively, if using Ente Auth, get started by adding an account (assuming you are running Ente Auth at `http://<machine-ip>:3002` or `http://localhost:3002`).

## Try the mobile app

You can install Ente Photos from [here](/photos/faq/installing) and Ente Auth from [here](/auth/faq/installing).

Connect to your server from [mobile apps](/self-hosting/installation/post-install/#step-6-configure-apps-to-use-your-server).

## What next?

Now that you have spinned up a cluster in quick manner, you may wish to install using a different way for your needs. Check the "Installation" section for information regarding that.

You can import your pictures from Google Takeout or from other services to Ente Photos. For more information, check out our [migration guide](/photos/migration/).

You can import your codes from other authenticator providers to Ente Auth. Check out the [migration guide](/auth/migration/) for more information.

## Queries?

If you need support, please ask on our community
[Discord](https://ente.io/discord) or start a discussion on
[GitHub](https://github.com/ente-io/ente/discussions/).
