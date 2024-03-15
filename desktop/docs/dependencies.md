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

During the build it uses
[electron-builder-notarize](https://github.com/karaggeorge/electron-builder-notarize)
to notarize the macOS binary.

### next-electron-server

This spins up a server for serving files using a protocol handler inside our
Electron process. This allows us to directly use the output produced by
`next build` for loading into our renderer process.

### electron-reload

Reloads contents of the BrowserWindow (renderer process) when source files are
changed.

* TODO (MR): Do we need this? Isn't the next-electron-server HMR covering this?

## DX

See [web/docs/dependencies#DX](../../web/docs/dependencies.md#dx) for the
general development experience related dependencies like TypeScript etc, which
are similar to that in the web code.

Some extra ones specific to the code here are:

* [concurrently](https://github.com/open-cli-tools/concurrently) for spawning
  parallel tasks when we do `yarn dev`.
