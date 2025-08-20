---
title: Quickstart script (Recommended) - Self-hosting
description: Self-hosting Ente with quickstart script
---

# Quickstart script (Recommended)

We provide a quickstart script which can be used for self-hosting Ente on your
machine in less than a minute.

## Requirements

Check out the [requirements](/self-hosting/installation/requirements) page to
get started.

## Getting started

Run this command on your terminal to setup Ente.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh)"
```

The above `curl` command does the following:

1. Creates a directory `./my-ente` in working directory.
2. Starts the containers required to run Ente upon prompting.

You should be able to access the web application at
[http://localhost:3000](http://localhost:3000) or
[http://machine-ip:3000](http://<machine-ip>:3000)

The data accessed by Museum is stored in `./data` folder inside `my-ente`
directory. It contains extra configuration files that is to be used (push
notification credentials, etc.)

::: tip

Check out [post-installation steps](/self-hosting/installation/post-install/)
for further usage.

:::
