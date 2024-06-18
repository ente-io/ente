---
title: Missing thumbnails
description:
    Troubleshooting when thumbnails are not being generated when uploading
    images in Ente Photos
---

# Missing thumbnails

## Black thumbnails

Users have reported an issue with Firefox which prevents the app from generating
thumbnails if the "block canvas fingerprinting" setting in Firefox is enabled
(i.e. `privacy.resistFingerprinting` is set to true in `about:config`). That
feature blocks access to the canvas, and the app needs the canvas to generate
thumbnails.
