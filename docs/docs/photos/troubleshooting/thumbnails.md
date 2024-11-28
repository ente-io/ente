---
title: Missing thumbnails
description:
    Troubleshooting when thumbnails are not being generated when uploading
    images in Ente Photos
---

# Missing or improper thumbnails

Firefox (including its other forks like Librewolf) prevents the app from
generating thumbnails if the "block canvas fingerprinting" setting in Firefox is
enabled (i.e. **`privacy.resistFingerprinting`** is set to true in
`about:config`). The app needs the canvas to generate thumbnails, and that
Firefox feature blocks access to the canvas. Ideally, Firefox should be
prompting for a permission, but some users have reported that sometime it
silently blocks access, and turning off that setting works.

Similar issues may arise if you are using an **extension** that blocks access to
the canvas, or some other browser that has similar restrictions.

In all these cases, you need to allow Ente access to the canvas for the
thumbnail to be generated properly.

Note that once the thumbnails are missing or have been incorrectly generated,
they cannot be viewed on any of the other clients (the thumbnails are only
generated once, during upload, so viewing it in a different place does not
change the already generated thumbnail).

There is currently no functionality to regenerate thumbnails in the above cases.
You will need to upload the affected files again.

Ente skips over files that have already been uploaded, so you can drag and drop
the original folder or zip again after removing the files without thumbnails,
and it'll only upload the files that are necessary.
