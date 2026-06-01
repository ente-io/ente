## Desktop app for Ente Photos

The sweetness of Ente Photos, right on your computer. Linux, Windows and macOS.

You can [**download** a pre-built binary from releases](https://github.com/ente-io/photos-desktop/releases/latest).

To know more about Ente, see [our main README](../README.md) or visit [ente.com](https://ente.com).

## Building from source

Clone this repository

```sh
git clone https://github.com/ente-io/ente
cd ente
```

Install the web dependencies

```sh
cd web
npm ci
```

Install the desktop dependencies

```sh
cd ../desktop
npm ci
```

Now you can run in development mode (supports hot reload for the renderer process)

```sh
npm run dev
```

Or create a binary for your platform

```sh
npm run build
```

That's the gist of it. For more development related documentation, see [docs](docs/README.md).
