---
title: Large uploads
description: Ente Photos and large (multi TB) uploads
---

# Large uploads

Some customers have reported an issue where their desktop app seems to get stuck
when they are trying to do the initial upload of multi-TB libraries.

A telltale sign of this is that app would seem to freeze during the upload, and
then restart again from the same state. If you were to look in the logs, you
would notice messages around the "renderer process crashing".

When this happens, you'll notice in the logs that it crashes when trying to
upload some specific large video, or a set of specific large videos.

As a workaround, you can **put these videos in a separate folder, complete the
rest of your upload, and then later upload this folder**.

Another alternative is to drag and drop the folder you are trying to upload into
the app instead of adding a folder watch or uploading a zip. This works better
because during a drag and drop, the app has direct access to the files via
browser APIs instead of going via the file system.

Note that the app will detect and skip over already uploaded items into an
album, so dragging and dropping the same folder again to upload to the same
album is fine.

> The underlying reason for this crash seeems to be the
> [4GB RAM usage limit for Electron apps](https://www.electronjs.org/blog/v8-memory-cage).
> We try to upload large videos by streaming them instead of reading them all in
> at once, but in some cases, even the streaming them seems to exceed the 4GB
> limit. We're trying to understand when this happens a bit more precisely, and
> if required, reimplement our uploads in a different way to avoid these.
