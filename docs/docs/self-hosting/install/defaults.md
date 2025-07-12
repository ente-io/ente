---
title: "Default Configuration"
description:
    "Detailed description of default configuration - ports, bucket, database,
    etc."
---

# Default Configuration

## Ports

The below format is according to how ports are mapped in Docker.
Typically,`<host-port>:<container-port>`

| Service                            | Type   | Host Port | Container Port |
| ---------------------------------- | ------ | --------- | -------------- |
| Museum                             | Server | 8080      | 8080           |
| Ente Photos                        | Web    | 3000      | 3000           |
| Ente Accounts                      | Web    | 3001      | 3001           |
| Ente Albums                        | Web    | 3002      | 3002           |
| [Ente Auth](https://ente.io/auth/) | Web    | 3003      | 3003           |
| [Ente Cast](http://ente.io/cast)   | Web    | 3004      | 3004           |
