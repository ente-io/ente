---
title: Uploads failing
description: Fixing upload errors when trying to self host Ente
---

# Uploads failing

If uploads to your self-hosted server are failing, make sure that
`credentials.yaml` has `yourserverip:3200` for all three minio locations.

By default it is `localhost:3200`, and it needs to be changed to an IP that is
accessible from both where you are running the Ente clients (e.g. the mobile
app) and also from within the Docker compose cluster.
