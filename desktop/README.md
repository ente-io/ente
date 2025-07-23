## Desktop app for Ente Photos

The sweetness of Ente Photos, right on your computer. Linux, Windows and macOS.

You can
[**download** a pre-built binary from releases](https://github.com/ente-io/photos-desktop/releases/latest).

To know more about Ente, see [our main README](../README.md) or visit
[ente.io](https://ente.io).

## Building from source

Clone this repository and change to this directory

```sh
git clone https://github.com/ente-io/ente
cd ente/desktop
```

Install dependencies (requires Yarn v1):

```sh
yarn install
```

Now you can run in development mode (supports hot reload for the renderer
process)

```sh
yarn dev
```

Or create a binary for your platform

```sh
yarn build
```

That's the gist of it. For more development related documentation, see
[docs](docs/README.md).
