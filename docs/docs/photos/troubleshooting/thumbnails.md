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

There is currently no functionality to regenerate thumbnails in the above cases.
You will need to upload the affected files again.

Ente skips over files that have already been uploaded, so you can drag and drop
the original folder or zip again after removing the files without thumbnails,
and it'll only upload the files that are necessary.
