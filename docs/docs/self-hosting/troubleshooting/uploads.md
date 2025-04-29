---
title: Uploads failing
description: Fixing upload errors when trying to self host Ente
---

# Uploads failing

If uploads to your minio are failing, you need to ensure that you've configured
the S3 bucket `endpoint` in `credentials.yaml` (or `museum.yaml`) to, say,
`yourserverip:3200`. This can be any host or port, it just need to be a value
that is reachable from both your client and from museum.

For more details, see [configuring-s3](/self-hosting/guides/configuring-s3).
