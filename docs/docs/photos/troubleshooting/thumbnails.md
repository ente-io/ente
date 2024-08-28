---
title: Missing thumbnails
description:
    Troubleshooting when thumbnails are not being generated when uploading
    images in Ente Photos
---

# Missing thumbnails

## Web

**Firefox** prevents the app from generating thumbnails if the "block canvas
fingerprinting" setting in Firefox is enabled (i.e.
**`privacy.resistFingerprinting`** is set to true in `about:config`). The app
needs the canvas to generate thumbnails, and that Firefox feature blocks access
to the canvas. Ideally, Firefox should be prompting for a permission, but some
users have reported that sometime it silently blocks access, and turning off
that setting works.

Similar issues may arise if you are using an extension that blocks access to the
canvas.

## Desktop

> [!NOTE]
>
> This issue has been fixed in the latest beta releases, and the fix will be
> also out in the next release, 1.7.4.

The only known case where thumbnails might be missing on desktop is when
uploading **videos** during a Google Takeout or watched folder sync on **Intel
macOS** machines. This is because the bundled ffmpeg that we use does not work
on Intel machines.

For images, we are able to fallback to other mechanisms for generating the
thumbnails, but for videos because of their potentially huge size, the app
doesn't try the fallback to avoid running out of memory.

In such cases, you will need to use the following workaround:

1.  Obtain a copy of `ffmpeg` binary that works on your Intel macOS. For
    example, you can install it via `brew`. If you already have `ffmpeg`
    installed you can copying it from `/usr/local/bin` (or whereever it was
    installed).

2.  Copy or symlink it to
    `/Applications/ente.app/Contents/Resources/app.asar.unpacked/node_modules/ffmpeg-static/ffmpeg`.

Alternatively, you can drag and drop the videos. Even without the above
workaround, thumbnail generation during video uploads via the normal folder
selection or drag and drop will work fine, since in those case we have access to
the video's data directly without reading it from a zip and can thus use the
fallback.

## Regenerating thumbnails

There is currently no functionality to regenerate thumbnails in the above cases.
You will need to upload the affected files again.

Ente skips over files that have already been uploaded, so you can drag and drop
the original folder or zip again after removing the files without thumbnails,
and it'll only upload the files that are necessary.
