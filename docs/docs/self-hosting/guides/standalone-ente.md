---
title: Installing Ente Standalone (without Docker)
description: Installing and setting up Ente standalone without docker.
---

# Installing and Deploying Ente Standalone (without Docker)

## Running Museum (Ente's server) without Docker

First, start by installing all the dependencies to get your machine ready for development. 

```sh 
# For MacOS
brew tap homebrew/core 
brew update 
brew install go 

# For Ubuntu based distros
sudo apt update && sudo apt upgrade 
sudo apt install golang-go
```

Alternatively, you can also download the latest binaries from ['All Release'](https://go.dev/dl/) page from the official website. 

```sh 
brew install postgres@15 
# Link the postgres keg 
brew link postgresql@15 

brew install libsodium 

# For Ubuntu based distros 
sudo apt install postgresql
sudo apt install libsodium23 libsodium-dev 
```

The package `libsodium23` might be installed already in some cases.

Installing pkg-config

```sh 
brew install pkg-config 

# For Ubuntu based distros 
sudo apt install pkg-config
```

## Starting Postgres 

### With pg_ctl 

```sh 
pg_ctl -D /usr/local/var/postgres -l logfile start 
```

Dependeing on the Operating System type the path for postgres binary or configuration file might be different, please check if the command keeps failing for you. 

Ideally, if you are on a Linux system with systemd as the init. You can also start postgres as a systemd service. After Installation execute the following commands: 

```sh 
sudo systemctl enable postgresql 
sudo systemctl daemon-reload && sudo systemctl start postgresql
```

### Create user 

```sh 
createuser -s postgres
```

## Start Museum 

```
export ENTE_DB_USER=postgres 
cd ente/server
go run cmd/museum/main.go
```

For live reloads, install [air](https://github.com/air-verse/air#installation). Then you can just call air after declaring the required environment variables. For example,

```
ENTE_DB_USER=ente_user
air
```

Once you are done with setting and running Museum, all you are left to do is run the web app and reverse_proxy it with a webserver. You can check the following resources for Deploying your web app. 

1. [Hosting the Web App](https://help.ente.io/self-hosting/guides/web-app).
2. [Running Ente Web app as a systemd Service](https://gist.github.com/mngshm/72e32bd483c2129621ed0d74412492fd)
