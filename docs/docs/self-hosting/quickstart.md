---
title: Quickstart
description: Getting started with self-hosting Ente
---

# Quickstart

For a quick preview of running Ente on your server, make sure you have the following installed on your system and meets the requirements mentioned below:

## Requirements

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
in the current working directory, prompts to start the cluster and starts all the containers required to run Ente.

![quickstart](/quickstart.png)

![self-hosted-ente](/web-app.webp)

> [!TIP] Important:
> If you have used quickstart for self-hosting Ente and are facing issues while  trying to run the cluster due to MinIO buckets not being created, please check  [troubleshooting MinIO](/self-hosting/troubleshooting/docker#minio-provisioning-error).
