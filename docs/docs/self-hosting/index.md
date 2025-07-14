---
title: Get Started - Self-hosting
description: Getting started with self-hosting Ente
---

# Get Started

The entire source code for Ente is open source,
[including the servers](https://ente.io/blog/open-sourcing-our-server/). This is the same code we use for our own cloud service.

For a quick preview of running Ente on your server, make sure you have the following installed on your system and meets the requirements mentioned below:

## Requirements

- A system with at least 1 GB of RAM and 1 CPU core
- [Docker Compose v2](https://docs.docker.com/compose/)

> For more details, check out [requirements page](/self-hosting/install/requirements)

## Set up the server

Run this command on your terminal to setup Ente.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh)"
```

The above command creates a directory `my-ente` in the current working directory, prompts to start the cluster after pulling the images and starts all the containers required to run Ente.

![quickstart](/quickstart.png)

## Try the web app

The first user to be registered will be treated as the admin user.

Open the web app at `http://<machine-ip>:3000` (or `http://localhost:3000` if using on same local machine) and select **Don't have an account?** to create a new user.

![Onboarding Screen](/onboarding.png)

Follow the prompts to sign up.

![Sign Up Page](/sign-up.png)

You will be prompted to enter verification code. Check the cluster logs using `sudo docker compose logs` and enter the same.

![Verification Code](/otp.png)

## Try the mobile app



## What next?


## Queries?

If you need support, please ask on our community
[Discord](https://ente.io/discord) or start a discussion on
[GitHub](https://github.com/ente-io/ente/discussions/).
