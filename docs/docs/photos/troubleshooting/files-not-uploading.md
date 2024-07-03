---
title: Files not uploading
description:
    Troubleshooting when files are not uploading from your Ente Photos app
---

# Files not uploading

## Network Issue

If you are using VPN, please try disabling the VPN or switching your provider.

## Web / Desktop

### Disable "Faster uploads"

We use a Cloudflare proxy to speed up uploads
([blog post](https://ente.io/blog/tech/making-uploads-faster/)). However, in
some network configurations (depending on the ISP) this might prevent uploads
from going through, so if you're having trouble with uploads please try after
disabling the "Faster uploads" setting in _Preferences > Advanced_.

### Certain file types are not uploading

The desktop/web app tries to detect if a particular file is video or image. If
the detection fails, then the app skips the upload. Please contact our
[support](mailto:support@ente.io) if you find that a valid file did not get
detected and uploaded.
