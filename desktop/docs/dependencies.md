# Dependencies

## Electron

[Electron](https://www.electronjs.org) is a cross-platform (Linux, Windows,
macOS) way for creating desktop apps using TypeScript.

Electron embeds Chromium and Node.js in the generated app's binary. The
generated app thus consists of two separate processes - the _main_ process, and
a _renderer_ process.

-   The _main_ process is runs the embedded node. This process can deal with the
    host OS - it is conceptually like a `node` repl running on your machine. In
    our case, the TypeScript code (in the `src/` directory) gets transpiled by
    `tsc` into JavaScript in the `build/app/` directory, which gets bundled in
    the generated app's binary and is loaded by the node (main) process when the
    app starts.

-   The _renderer_ process is a regular web app that gets loaded into the
    embedded Chromium. When the main process starts, it creates a new "window"
    that shows this embedded Chromium. In our case, we build and bundle a static
    export of the [Photos web app](../web/README.md) in the generated app. This
    gets loaded by the embedded Chromium at runtime, acting as the app's UI.

There is also a third environment that gets temporarily created:

-   The [preload script](../src/preload.ts) acts as a gateway between the _main_
    and the _renderer_ process. It runs in its own isolated environment.

### electron-builder

[Electron Builder](https://www.electron.build) is used for packaging the app for
distribution.

### next-electron-server

This spins up a server for serving files using a protocol handler inside our
Electron process. This allows us to directly use the output produced by
`next build` for loading into our renderer process.
