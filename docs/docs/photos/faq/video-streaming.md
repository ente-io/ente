---
title: Video Streaming FAQ
description:
    Frequently asked questions about Ente's Video Streaming feature
---

# Video Streaming

## Mobile

### How to enable Video Streaming?

- Open the Drawer.
- In that Go to General -> Advanced
- Switch on the Toggle for `Video Streaming`

### What happens when I enable Video Streaming

It adds all the past 30 days videos to a queue and begin creation of a preview file for both local and remote videos.

This may consume bandwidth for downloading of remote files and uploading of the generated preview files.

### What is the Preview file

The preview file is a HLS Encrypted video file with a .m3u8 playlist that will help us play the video with support of random seeking without downloading the complete video. Currently it converts video into 720p with 2mbps bitrate H.264 format.

The preview video file (.ts) is single file which is AES encrypted whereas the playlist file (.m3u8) is encrypted using the ChaCha20 Encryption method so even we can't read the duration and number of chunks of the video file.

### Will the previews consume space in my storage?

No, as of today we are not counting the preview files in your storage consumption, but this might change in future.

### Something doesn't seem right, what to do?

As Video Streaming is still in beta, some things might not working correctly. For that you can either use the #feedback channel in discord or send a ticket to support at ente.io with the relevant title and message regarding the issue.
