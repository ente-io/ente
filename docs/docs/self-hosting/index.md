---
title: Self Hosting
description: Getting started self hosting Ente Photos and/or Ente Auth
---

# Self Hosting

The entire source code for Ente is open source,
[including the servers](https://ente.io/blog/open-sourcing-our-server/). This is
the same code we use for our own cloud service.

## Requirements

### Hardware

The server is capable of running on minimal resource requirements as a
lightweight Go binary, since most of the intensive computational tasks are done
on the client. It performs well on small cloud instances, old laptops, and even
[low-end embedded devices](https://github.com/ente-io/ente/discussions/594).

### Software

#### Operating System

Any Linux or \*nix operating system, Ubuntu or Debian is recommended to have a
good Docker experience. Non-Linux operating systems tend to provide poor
experience with Docker and difficulty with troubleshooting and assistance.

#### Docker

Required for running Ente's server, web application and dependent services
(database and object storage)

## Getting started

Run this command on your terminal to setup Ente.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh)"
```

The above `curl` command pulls the Docker image, creates a directory `my-ente`
in the current working directory and prompts to start the cluster, which upon
entering `y`, starts all the containers required to run Ente.

![quickstart](/quickstart.png)

![self-hosted-ente](/web-app.webp)

## Queries?

If you need support, please ask on our community
[Discord](https://ente.io/discord) or start a discussion on
[GitHub](https://github.com/ente-io/ente/discussions/).
