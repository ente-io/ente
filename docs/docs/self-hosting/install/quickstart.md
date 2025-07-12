---
title: Quickstart Script
description: Self-hosting Ente with quickstart script
---

# Quickstart

We provide a quickstart script which can be used for self-hosting Ente on your machine.

## Requirements

Check out the [requirements](/self-hosting/install/requirements) page to get started.

## Getting started

Run this command on your terminal to setup Ente.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh)"
```

The above `curl` command pulls the Docker image, creates a directory `my-ente`
in the current working directory, prompts to start the cluster and starts all the containers required to run Ente.

![quickstart](/quickstart.png)

![self-hosted-ente](/web-app.webp)
