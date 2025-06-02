---
title: Video streaming FAQ
description: Frequently asked questions about Ente's video streaming feature
---

# Video streaming

> [!NOTE]
>
> Video streaming is available in beta on mobile apps starting v0.9.98 and on
> desktop starting v1.7.13.

### How to enable video streaming?

#### On mobile

- Open Settings -> General -> Advanced
- Enable the toggle for `Streamable videos`

#### On desktop

- Open Settings -> Preferences
- Enable the toggle for `Streamable videos`

### What happens when I enable video streaming?

#### On mobile

Enabling video streaming will start processing videos captured in the last 30
days, generating streams for each. Both local and remote videos will be
processed, so this may consume bandwidth for downloading of remote files and
uploading of the generated streams.

#### On desktop

When enabled, the desktop app will generate streams both for new uploads, and
also for all existing videos that were previously uploaded.

Stream generation is CPU intensive and can take time so the app will continue
processing them in the background. Clicking on search bar will show "Processing
videos..." when stream generation is happening.

### How can I view video streams?

### On mobile

Settings -> Backup > Backup status will show details regarding the processing
status for videos. Processed videos will have a green play button next to them.
You can open these videos by tapping on them.

Processed videos will show a `Play stream` button, clicking which will load and
play the stream.

Clicking on the `Info` icon within the original video will show details about
the generated stream.

### On desktop and web

Desktop and web app will automatically play the streaming version of a video if
it has been already generated. The quality selector will show "Auto" when
playing the stream.

### What is a stream?

Stream is an encrypted HLS file with an `.m3u8` playlist that helps play a video
with support for seeking **without** downloading the full file.

Currently it converts videos into `720p` with `2mbps` bitrate in `H.264` format.
The generated stream is single blob (encrypted with AES) while the playlist file
(`.m3u8`) is another blob (encrypted using XChaCha20).

We cannot read the contents, duration or the number of chunks within the
generated stream.

### Will streams consume space in my storage?

While this feature is in beta, we will not count the storage consumed by your
streams against your storage quota. This may change in the future. If it does,
we will provide an option to opt-in to one of the following:

1. Original videos only
2. Compressed streams only
3. Both

### Something doesn't seem right, what to do?

As video streaming is still in beta, some things might not work correctly.
Please create a thread within the `#feedback` channel on
[Discord](https://discord.com/channels/948937918347608085/1121126215995113552)
or reach out to [support@ente.io](mailto:support@ente.io).
