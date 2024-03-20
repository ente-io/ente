## Desktop app for Ente Photos

The sweetness of Ente Photos, right on your computer. Linux, Windows and macOS.

You can
[**download** a pre-built binary from releases](https://github.com/ente-io/photos-desktop/releases/latest).

To know more about Ente, see [our main README](../README.md) or visit
[ente.io](https://ente.io).

## Building from source

Fetch submodules

```sh
git submodule update --init --recursive
```

Install dependencies

```sh
yarn install
```

Run in development mode (with hot reload)

```sh
yarn dev
```

> [!CAUTION]
>
> `yarn dev` is currently not working (we'll fix soon). If you just want to
> build from source and use the generated binary, use `yarn build`.

Or create a binary for your platform

```sh
yarn build
```

That's the gist of it. For more development related documentation, see
[docs](docs/README.md).
