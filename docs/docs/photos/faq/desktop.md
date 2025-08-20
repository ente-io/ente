---
title: Desktop app FAQ
description: An assortment of frequently asked questions about Ente Photos desktop app
---

# Desktop app FAQ

### App updates

**How do I ensure that the Ente desktop app stays up to date on my system?**

Ente desktop includes an auto-update feature, ensuring that whenever updates are
deployed, the app will automatically download and install them. You don't need
to manually update the software.

### Upload errors

**How do I identify which files experienced upload issues within the desktop
app?**

Check the sections within the upload progress bar for "Failed Uploads," "Ignored
Uploads," and "Unsuccessful Uploads."

### Icon update

**I updated my Linux app, but it is still showing the old icon**

You might need to update the icon cache of your Linux desktop environment.

The easiest way to fix this would be to restart your computer (or logout and
login again into your desktop environment). It should also be possible to do
this without restarting, but the steps for refreshing the icon cache would then
be specific to your distro (e.g. `xdg-desktop-menu forceupdate`).

> [!NOTE]
>
> If you're using an AppImage and not seeing the icon, you'll need to
> [enable AppImage desktop integration](/photos/troubleshooting/desktop-install/#appimage-desktop-integration).
