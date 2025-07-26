---
title: Environment variables and defaults - Self-hosting
description:
    "Information about all the configuration variables needed to run Ente along
    with description on default configuration"
---

# Environment variables and defaults

The environment variables needed for running Ente and the default configuration
are documented below:

## Environment Variables

A self-hosted Ente instance has to specify endpoints for both Museum (the
server) and web apps.

This document outlines the essential environment variables and port mappings of
the web apps.

Here's the list of environment variables that is used by the cluster:

| Service    | Environment Variable  | Description                                                                                     | Default Value                   |
| ---------- | --------------------- | ----------------------------------------------------------------------------------------------- | ------------------------------- |
| `web`      | `ENTE_API_ORIGIN`     | Alias for `NEXT_PUBLIC_ENTE_ENDPOINT`. API Endpoint for Ente's API (Museum).                    | http://localhost:8080           |
| `web`      | `ENTE_ALBUMS_ORIGIN`  | Alias for `NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT`. Base URL for Ente Album, used for public sharing. | http://localhost:3002           |
| `postgres` | `POSTGRES_USER`       | Username for PostgreSQL database                                                                | `pguser`                        |
| `postgres` | `POSTGRES_DB`         | Name of database for use with Ente                                                              | `ente_db`                       |
| `postgres` | `POSTGRES_PASSWORD`   | Password for PostgreSQL database's user                                                         | Randomly generated (quickstart) |
| `minio`    | `MINIO_ROOT_USER`     | Username for MinIO                                                                              | Randomly generated (quickstart) |
| `minio`    | `MINIO_ROOT_PASSWORD` | Password for MinIO                                                                              | Randomly generated (quickstart) |

## Default Configuration

Self-hosted Ente clusters have certain default configuration for ease of use,
which is documented below to understand its behavior:

### Ports

The below format is according to how ports are mapped in Docker when using the
quickstart script. The mapping is of the format `<host-port>:<container-port>`
in `ports` in compose file.

| Service                                                 | Type     | Host Port | Container Port |
| ------------------------------------------------------- | -------- | --------- | -------------- |
| Museum                                                  | Server   | 8080      | 8080           |
| Ente Photos                                             | Web      | 3000      | 3000           |
| Ente Accounts                                           | Web      | 3001      | 3001           |
| Ente Albums                                             | Web      | 3002      | 3002           |
| [Ente Auth](https://ente.io/auth/)                      | Web      | 3003      | 3003           |
| [Ente Cast](https://help.ente.io/photos/features/cast/) | Web      | 3004      | 3004           |
| MinIO                                                   | S3       | 3200      | 3200           |
| PostgreSQL                                              | Database |           | 5432           |
