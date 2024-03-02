## Desktop app for Ente Photos

The sweetness of Ente Photos, right on your computer. Linux, Windows and macOS.

You can [**download** a pre-built binary from
releases](https://github.com/ente-io/photos-desktop/releases/latest).

To know more about Ente, see [our main README](../README.md) or visit
[ente.io](https://ente.io).

## Building from source

> [!CAUTION]
>
> We moved a few things around when switching to a monorepo recently, so this
> folder might not build with the instructions below. Hang tight, we're on it,
> will fix things if.

Fetch submodules

```sh
git submodule update --init --recursive
```

Install dependencies

```sh
yarn install
```

Run the app

```sh
yarn start
```

To recompile automatically using electron-reload, run this in a separate
terminal:

```bash
yarn watch
```
