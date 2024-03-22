## Desktop app for Ente Photos

The sweetness of Ente Photos, right on your computer. Linux, Windows and macOS.

You can
[**download** a pre-built binary from releases](https://github.com/ente-io/photos-desktop/releases/latest).

To know more about Ente, see [our main README](../README.md) or visit
[ente.io](https://ente.io).

## Building from source

> [!CAUTION]
>
> We're improving the security of the desktop app further by migrating to
> Electron's sandboxing and contextIsolation. These updates are still WIP and
> meanwhile the instructions below might not fully work on the main branch.

Fetch submodules

```sh
git submodule update --init --recursive
```

Install dependencies

```sh
yarn install
```

Run in development mode (supports hot reload for the renderer process)

```sh
yarn dev
```

Or create a binary for your platform

```sh
yarn build
```

That's the gist of it. For more development related documentation, see
[docs](docs/README.md).
