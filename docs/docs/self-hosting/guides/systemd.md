---
title: Running Ente using systemd - Self-hosting
description: Running Ente services (Museum and web application) via systemd
---

# Running Ente using `systemd`

On Linux distributions using `systemd` as initialization system, Ente can be configured to run as a background service, upon system startup by using service files.

## Museum as a background service

Please check the below links if you want to run Museum as a service, both of
them are battle tested.

1. [How to run museum as a systemd service](https://gist.github.com/mngshm/a0edb097c91d1dc45aeed755af310323)
2. [Museum.service](https://github.com/ente-io/ente/blob/23e678889189157ecc389c258267685934b83631/server/scripts/deploy/museum.service#L4)

Once you are done with setting and running Museum, all you are left to do is run
the web app and reverse_proxy it with a webserver. You can check the following
 resources for Deploying your web app.

1. [Running Ente Web app as a systemd Service](https://gist.github.com/mngshm/72e32bd483c2129621ed0d74412492fd)

## References

1. [How to run museum as a systemd service](https://gist.github.com/mngshm/a0edb097c91d1dc45aeed755af310323)
2. [Museum.service](https://github.com/ente-io/ente/blob/23e678889189157ecc389c258267685934b83631/server/scripts/deploy/museum.service#L4)
3. [Running Ente Web app as a systemd Service](https://gist.github.com/mngshm/72e32bd483c2129621ed0d74412492fd)
