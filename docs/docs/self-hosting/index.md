---
title: Self Hosting
description: Getting started self hosting Ente Photos and/or Ente Auth
---

# Self Hosting

The entire source code for Ente is open source, including the servers. This is
the same code we use for our own cloud service.

> [!TIP]
>
> You might find our [blog post](https://ente.io/blog/open-sourcing-our-server/)
> announcing the open sourcing of our server useful.

## System requirements

The server has minimal resource requirements, running as a lightweight Go
binary. It performs well on small cloud instances, old laptops, and even
[low-end embedded devices](https://github.com/ente-io/ente/discussions/594).

## Getting started

Run this command on your terminal to setup Ente.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh)"
```

The above `curl` command pulls the Docker image, creates a directory `my-ente`
in the current working directory and starts all containers required to run Ente.

![quickstart](/quickstart.png)

![self-hosted-ente](/web-app.webp)

## Queries?

If you need support, please ask on our community
[Discord](https://ente.io/discord) or start a discussion on
[GitHub](https://github.com/ente-io/ente/discussions/).
