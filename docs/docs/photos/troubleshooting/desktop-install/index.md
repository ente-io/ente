---
title: Desktop installation
description: Troubleshooting issues when installing the Ente Photos desktop app
---

# Desktop app installation

The latest version of the Ente Photos desktop app can be downloaded from
[ente.io/download](https://ente.io/download). If you're having trouble, please
see if any of the following cases apply.

## AppImages on ARM64 Linux

If you're on an ARM64 machine running Linux, and the AppImages doesn't do
anything when you run it, you will need to run the following command on your
machine:

```sh
sudo ln -s /usr/lib/aarch64-linux-gnu/libz.so{.1,}
```

It is possible that the exact path might be different on your machine. Briefly,
what we need to do is create `libz.so` as an alias for `libz.so.1`. For more
details, see the following bugs in upstream repositories:

-   libz.so cannot open shared object file on ARM64 -
    [/github.com/AppImage/AppImageKit/issues/1092](https://github.com/AppImage/AppImageKit/issues/1092)

-   libz.so: cannot open shared object file with Ubuntu arm64 -
    [github.com/electron-userland/electron-builder/issues/7835](https://github.com/electron-userland/electron-builder/issues/7835)

## AppImage says it requires FUSE

See
[docs.appimage.org](https://docs.appimage.org/user-guide/troubleshooting/fuse.html#the-appimage-tells-me-it-needs-fuse-to-run).

tl;dr; for example, on Ubuntu,

```sh
sudo apt install libfuse2
```

## Windows

If the app stops with an "A JavaScript error occurred in the main process - The
specified module could not be found" error on your Windows machine when you
start it, then you might need to install the VC++ runtime from Microsoft.

This is what the error looks like:

![Error when VC++ runtime is not installed](windows-vc.png){width=500px}

You can install the Microsoft VC++ redistributable runtime from here:<br/>
https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist?view=msvc-170#latest-microsoft-visual-c-redistributable-version
