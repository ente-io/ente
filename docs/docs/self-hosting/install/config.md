---
title: "Configuration - Self-hosting"
description:
    "Information about all the configuration variables needed to run Ente along
    with description on default configuration"
---

# Configuration

The environment variables needed for running Ente, configuration variables
present in Museum's configuration file and the default configuration are
documented below:

## Environment Variables

A self-hosted Ente instance requires specific endpoints in both Museum (the
server) and web apps. This document outlines the essential environment variables
and port mappings of the web apps.

Here's the list of environment variables that need to be configured:

| Service | Environment Variable | Description                                      | Default Value         |
| ------- | -------------------- | ------------------------------------------------ | --------------------- |
| Web     | `ENTE_API_ORIGIN`    | API Endpoint for Ente's API (Museum)             | http://localhost:8080 |
| Web     | `ENTE_ALBUMS_ORIGIN` | Base URL for Ente Album, used for public sharing | http://localhost:3002 |

## Config File

## Default Configuration

### Ports

The below format is according to how ports are mapped in Docker when using quickstart script.
The mapping is of the format `- <host-port>:<container-port>` in `ports`.

| Service                            | Type   | Host Port | Container Port |
| ---------------------------------- | ------ | --------- | -------------- |
| Museum                             | Server | 8080      | 8080           |
| Ente Photos                        | Web    | 3000      | 3000           |
| Ente Accounts                      | Web    | 3001      | 3001           |
| Ente Albums                        | Web    | 3002      | 3002           |
| [Ente Auth](https://ente.io/auth/) | Web    | 3003      | 3003           |
| [Ente Cast](http://ente.io/cast)   | Web    | 3004      | 3004           |
