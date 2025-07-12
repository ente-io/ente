---
title: Running Ente Without Docker - Self-hosting
description: Installing and setting up Ente without Docker
---

# Running Ente without Docker

## Running Museum (Ente's server) without Docker

First, start by installing all the dependencies to get your machine ready for
development.

- For macOS
    ```sh
    brew tap homebrew/core
    brew update
    brew install go
    ```
- For Debian/Ubuntu-based distros
    ``` sh
    sudo apt update && sudo apt upgrade
    sudo apt install golang-go
    ```

Alternatively, you can also download the latest binaries from
['All Release'](https://go.dev/dl/) page from the official website.

- For macOS
    ```sh
    brew install postgres@15
    # Link the postgres keg
    brew link postgresql@15
    brew install libsodium
    ```
- For Debian/Ubuntu-based distros
    ``` sh
    sudo apt install postgresql
    sudo apt install libsodium23 libsodium-dev
    ```

The package `libsodium23` might be installed already in some cases.

Install `pkg-config`

- For macOS
    ```sh
    brew install pkg-config
    ```
- For Debian/Ubuntu-based distros
    ``` sh
    sudo apt install pkg-config
    ```

## Starting Postgres

### With `pg_ctl`

```sh
pg_ctl -D /usr/local/var/postgres -l logfile start
```

Depending on the operating system type, the path for postgres binary or
configuration file might be different, please check if the command keeps failing
for you.

Ideally, if you are on a Linux system with `systemd` as the initialization ("init") system. You can also
start postgres as a systemd service. After Installation execute the following
commands:

```sh
sudo systemctl enable postgresql
sudo systemctl daemon-reload && sudo systemctl start postgresql
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

You can also add the export line to your shell's RC file, to avoid exporting the
environment variable every time.

For live reloads, install [air](https://github.com/air-verse/air#installation).
Then you can just call air after declaring the required environment variables.
For example,

```sh
ENTE_DB_USER=postgres
air
```

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
