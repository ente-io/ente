---
title: Installing Ente Standalone (without Docker)
description: Guide for installing and setting up Ente standalone without docker.
---

# Guide to Installing and Deploying Ente Standalone (without Docker)

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

# 
