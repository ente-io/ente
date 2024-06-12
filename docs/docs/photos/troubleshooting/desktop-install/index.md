---
title: Desktop installation
description: Troubleshooting issues when installing the Ente Photos desktop app
---

# Desktop app installation

The latest version of the Ente Photos desktop app can be downloaded from
[ente.io/download](https://ente.io/download). If you're having trouble, please
see if any of the following cases apply.

-   [Windows](#windows)
-   [Linux](#linux)

## Windows

If the app stops with an "A JavaScript error occurred in the main process - The
specified module could not be found" error on your Windows machine when you
start it, then you might need to install the VC++ runtime from Microsoft.

This is what the error looks like:

![Error when VC++ runtime is not installed](windows-vc.png){width=500px}

You can install the Microsoft VC++ redistributable runtime from here:<br/>
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#latest-microsoft-visual-c-redistributable-version

## Linux

### AppImage desktop integration

AppImages are not fully standalone, and they require additional steps to enable
full "desktop integration":

-   Showing the app icon,
-   Surfacing the app in the list of installed apps,
-   Handling redirection after passkey verification.

All the ways of enabling AppImage desktop integration are mentioned in
[AppImage documentation](https://docs.appimage.org/user-guide/run-appimages.html#integrating-appimages-into-the-desktop).

For example, you can download the
[appimaged](https://github.com/probonopd/go-appimage/releases) AppImage, run it,
and then download the Ente Photos AppImage into your `~/Downloads` folder.
_appimaged_ will then pick it up automatically.

### AppImages on ARM64

If you're on an ARM64 machine running Linux, and the AppImages doesn't do
anything when you run it, you will need to run the following command on your
machine:

```sh
sudo ln -s /usr/lib/aarch64-linux-gnu/libz.so{.1,}
```

It is possible that the exact path might be different on your machine. Briefly,
what we need to do is create `libz.so` as an alias for `libz.so.1`. For more
details, see the following upstream issues:

-   libz.so cannot open shared object file on ARM64 -
    [AppImage/AppImageKit/issues/1092](https://github.com/AppImage/AppImageKit/issues/1092)

-   libz.so: cannot open shared object file with Ubuntu arm64 -
    [electron-userland/electron-builder/issues/7835](https://github.com/electron-userland/electron-builder/issues/7835)

### AppImage says it requires FUSE

See
[docs.appimage.org](https://docs.appimage.org/user-guide/troubleshooting/fuse.html#the-appimage-tells-me-it-needs-fuse-to-run).

tl;dr; for example, on Ubuntu,

```sh
sudo apt install libfuse2
```

### Linux SUID error

On some Linux distributions, if you run the AppImage from the CLI, it might fail
with the following error:

> The SUID sandbox helper binary was found, but is not configured correctly.

This happens when you try to run the AppImage from the command line. If you
instead double click on the AppImage in your Files browser, then it should start
properly.

If you do want to run it from the command line, you can do so by passing the
`--no-sandbox` flag when executing the AppImage. e.g.

```sh
./ente.AppImage --no-sandbox
```

For more details, see this upstream issue on
[electron](https://github.com/electron/electron/issues/17972).
