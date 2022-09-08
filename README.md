# bhari-frame (heavy-frame)

Desktop app for [ente.io](https://ente.io) build with [electron](https://electronjs.org) and loads of ❤️.

## Disclaimer

We are aware that electron is a sub-optimal choice for building desktop applications.

The goal of this app was to
1. provide a stable environment for customers to back up large amounts of data reliably
2. export uploaded data from our servers to their local hard drives.

Electron was the best way to reuse our battle tested code from [bada-frame](https://github.com/ente-io/bada-frame) that powers [web.ente.io](https://web.ente.io).

As an archival solution built by a small team, we are hopeful that this project will help us keep our stack lean, while ensuring a painfree life for our customers.

If you are running into issues with this app, please drop a mail to [support@ente.io](mailto:support@ente.io) and we'll be very happy to help.

## Download

- [Latest Release](https://github.com/ente-io/bhari-frame/releases/latest)

*User contributed ports*

- [AUR](https://aur.archlinux.org/packages/ente-desktop-appimage):
  `yay -S ente-desktop-appimage`

## Building from source

You'll need to have node (and yarn) installed on your machine. e.g. on macOS you
can do `brew install node`. After that, you can run the following commands to
fetch and build from source.

```bash
# Clone this repository
git clone https://github.com/ente-io/bhari-frame

# Go into the repository
cd bhari-frame

# Clone submodules (recursively)
git submodule update --init --recursive

# Install packages
yarn

# Run the app
yarn start
```

### Re-compile automatically

To recompile automatically and to allow using
[electron-reload](https://github.com/yan-foto/electron-reload), run this in a
separate terminal:

```bash
yarn watch
```
