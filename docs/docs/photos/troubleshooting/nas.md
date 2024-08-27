---
title: Avoiding NAS
description: Ente Photos and NAS (network drives)
---

# Network drives

The Ente Photos desktop app currently does not support NAS (network drives).

The app will actually work, and in some cases it will work fine too, but in
practice we have found that network storage products sometimes have flaky file
system emulation that causes bad performance during uploads, or when trying to
directly stream chunks of Google Takeout zips that are stored on network drives.

In particular, the folder watch functionality suffers a lot since the app needs
access to file system events to detect changes to the users files so that they
can be uploaded whenever there are changes.

Since are high chances of the user having a subpar experience, we request
customers to avoid using the desktop app directly with network attached storage
and instead temporarily copy the files to their local storage for uploads, and
avoid watching folders that live on a network drive.
