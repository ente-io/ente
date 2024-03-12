## Desktop app for Ente Photos

The sweetness of Ente Photos, right on your computer. Linux, Windows and macOS.

You can [**download** a pre-built binary from
releases](https://github.com/ente-io/photos-desktop/releases/latest).

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

Create a binary for your platform

```sh
yarn build
```

## Developing

Instead of building, you can run the app in development mode

```sh
yarn dev
```

> [!CAUTION]
>
> `yarn dev` is currently not working (we'll fix soon). If you just want to
> build from source and use the generated binary, use `yarn build` as described
> above.

This'll launch a development server to serve the pages loaded by the renderer
process, and will hot reload on changes.

If you also want hot reload for the main process, run this in a separate
terminal:

```sh
yarn watch
```
