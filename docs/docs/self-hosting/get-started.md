---
title: Get Started - Self-hosting
description: Getting started with self-hosting Ente
---

# Get Started

The entire source code for Ente is open source,
[including the servers](https://ente.io/blog/open-sourcing-our-server/).

This is the same code we use for our own cloud service.

For a quick preview of running Ente on your server, make sure you have the following installed on your system and meets the requirements mentioned below:

## Requirements

- A system with at least 2 GB of RAM and 1 CPU core
- [Docker Compose v2](https://docs.docker.com/compose/)

> For more details, check out [requirements page](/self-hosting/install/requirements)

## Set up the server

Run this command on your terminal to setup Ente.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh)"
```

The above `curl` command pulls the Docker image, creates a directory `my-ente`
in the current working directory, prompts to start the cluster and starts all the containers required to run Ente.

![quickstart](/quickstart.png)

![self-hosted-ente](/web-app.webp)


## Queries?

If you need support, please ask on our community
[Discord](https://ente.io/discord) or start a discussion on
[GitHub](https://github.com/ente-io/ente/discussions/).
