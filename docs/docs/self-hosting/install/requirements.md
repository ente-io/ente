---
title: Requirements
description: Requirements for self-hosting Ente
---

# Requirements

The server is capable of running on minimal resource requirements as a
lightweight Go binary, since most of the intensive computational tasks are done
on the client. It performs well on small cloud instances, old laptops, and even
[low-end embedded devices](https://github.com/ente-io/ente/discussions/594).

## Software

### Operating System

Any Linux or \*nix operating system, Ubuntu or Debian is recommended to have a
good Docker experience. Non-Linux operating systems tend to provide poor
experience with Docker and difficulty with troubleshooting and assistance.

### Docker

Required for running Ente's server, web application and dependent services
(database and object storage)
