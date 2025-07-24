---
title: Running Ente Without Docker - Self-hosting
description: Installing and setting up Ente without Docker
---

# Running Ente without Docker

If you wish to run Ente from source without using Docker, follow the steps described below:

## Pre-requisites

1. **Go:** Install Go on your system. This is needed for building Museum (Ente's server)
    
    ``` shell
    sudo apt update && sudo apt upgrade
    sudo apt install golang-go
    ```

    Alternatively, you can also download the latest binaries
    from the [official website](https://go.dev/dl/).

2. **PostgreSQL and `libsodium`:** Install PostgreSQL (database) and `libsodium` (high level API for encryption) via package manager.
    
    ``` shell
    sudo apt install postgresql
    sudo apt install libsodium23 libsodium-dev
    ```

3. **`pkg-config`:** Install `pkg-config` for dependency handling.
    
    ``` shell
    sudo apt install pkg-config
    ```

Start the database using `systemd` automatically when the system starts.
``` shell
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

Ensure the database is running using

``` shell
sudo systemctl status postgresql
```

### Create user

```sh
sudo useradd postgres
```

## Start Museum

Start by cloning ente to your system.

```sh
git clone https://github.com/ente-io/ente
```

```sh
export ENTE_DB_USER=postgres
cd ente/server
go run cmd/museum/main.go
```

You can also add the export line to your shell's RC file, to avoid exporting the environment variable every time.

## Museum as a background service

Please check the below links if you want to run Museum as a service, both of
them are battle tested.

1. [How to run museum as a systemd service](https://gist.github.com/mngshm/a0edb097c91d1dc45aeed755af310323)
2. [Museum.service](https://github.com/ente-io/ente/blob/23e678889189157ecc389c258267685934b83631/server/scripts/deploy/museum.service#L4)

Once you are done with setting and running Museum, all you are left to do is run
the web app and reverse_proxy it with a webserver. You can check the following
resources for Deploying your web app.

1. [Hosting the Web App](https://help.ente.io/self-hosting/guides/web-app).
2. [Running Ente Web app as a systemd Service](https://gist.github.com/mngshm/72e32bd483c2129621ed0d74412492fd)
