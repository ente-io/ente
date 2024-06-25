# Dependencies

-   [Electron](#electron)
-   [Dev dependencies](#dev)
-   [Functionality](#functionality)

## Electron

[Electron](https://www.electronjs.org) is a cross-platform (Linux, Windows,
macOS) way for creating desktop apps using TypeScript.

Electron embeds Chromium and Node.js in the generated app's binary. The
generated app thus consists of two separate processes - the _main_ process, and
a _renderer_ process.

-   The _main_ process runs the embedded node. This process can deal with the
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

### Packaging

[Electron Builder](https://www.electron.build) is used for packaging the app for
distribution.

During the build it uses
[electron-builder-notarize](https://github.com/karaggeorge/electron-builder-notarize)
to notarize the macOS binary.

### Updates

[electron-updater](https://www.electron.build/auto-update#debugging), while a
separate package, is also a part of Electron Builder. It provides an alternative
to Electron's built in auto updater, with a more flexible API. It supports auto
updates for the DMG, AppImage, DEB, RPM and NSIS packages.

[compare-versions](https://github.com/omichelsen/compare-versions) is used for
semver comparisons when we decide when to trigger updates.

### Logging

[electron-log](https://github.com/megahertz/electron-log) is used for logging.
Specifically, it allows us to log to a file (in addition to the console of the
Node.js process), and also handles log rotation and limiting the size of the log
files.

### next-electron-server

This spins up a server for serving files using a protocol handler inside our
Electron process. This allows us to directly use the output produced by
`next build` for loading into our renderer process.

### Others

-   [any-shell-escape](https://github.com/boazy/any-shell-escape) is for
    escaping shell commands before we execute them (e.g. say when invoking the
    embedded ffmpeg CLI).

-   [auto-launch](https://github.com/Teamwork/node-auto-launch) is for
    automatically starting our app on login, if the user so wishes.

-   [electron-store](https://github.com/sindresorhus/electron-store) is used for
    persisting user preferences and other arbitrary data.

## Dev

See [web/docs/dependencies#dev](../../web/docs/dependencies.md#dev) for the
general development experience related dependencies like TypeScript etc, which
are similar to that in the web code.

Some extra ones specific to the code here are:

-   [shx](https://github.com/shelljs/shx) for providing a portable way to use
    Unix commands in our `package.json` scripts. This allows us to use the same
    commands (like `ln`) across different platforms like Linux and Windows.

-   [@tsconfig/recommended](https://github.com/tsconfig/bases) gives us a base
    tsconfig for the Node.js version that our current Electron version uses.

## Functionality

### Format conversion

The main tool we use is for arbitrary conversions is ffmpeg. To bundle a
(platform specific) static binary of ffmpeg with our app, we use
[ffmpeg-static](https://github.com/eugeneware/ffmpeg-static).

> There is a significant (~20x) speed difference between using the compiled
> ffmpeg binary and using the wasm one (that our renderer process already has).
> Which is why we bundle it to speed up operations on the desktop app.

In addition, we also bundle a static Linux binary of imagemagick in our extra
resources (`build`) folder. This is used for thumbnail generation on Linux.

On macOS, we use the `sips` CLI tool for conversion, but that is already
available on the host machine, and is not bundled with our app.

### AI/ML

[onnxruntime-node](https://github.com/Microsoft/onnxruntime) is used as the
AI/ML runtime. It powers both natural language searches (using CLIP) and face
detection (using YOLO).

[jpeg-js](https://github.com/jpeg-js/jpeg-js#readme) is used for decoding JPEG
data into raw RGB bytes before passing it to ONNX.

html-entities is used by the bundled clip-bpe-ts tokenizer for CLIP.

### Watch Folders

[chokidar](https://github.com/paulmillr/chokidar) is used as a file system
watcher for the watch folders functionality.

### ZIP

[node-stream-zip](https://github.com/antelle/node-stream-zip) is used for
reading of large ZIP files (e.g. during imports of Google Takeout ZIPs).

[lru-cache](https://github.com/isaacs/node-lru-cache) is used to cache file ZIP
handles to avoid reopening them for every operation.
