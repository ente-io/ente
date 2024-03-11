# Electron

[Electron](https://www.electronjs.org) is a cross-platform (Linux, Windows,
macOS) way for creating desktop apps using TypeScript.

Electron embeds Chromium and Node.js in the generated app's binary. The
generated app thus consists of two separate processes - the _main_ process, and
a _renderer_ process.

* The _renderer_ process is a regular web app that gets loaded into the embedded
  Chromium. In our case, we build a static export of the [Photos web
  app](../web/README.md) and bundle it in the generated app's binary - at
  runtime, the embedded Chromium loads this.

* The _main_ process is runs the embedded Node.js. This code can deal with the
 host OS - it is conceptually like a `node` repl running on your machine. In our
 case, the TypeScript code (in the `src/` directory) gets transpiled by `tsc`
 into JavaScript in the `app/` directory, which gets bundled in the generated
 app's binary and is loaded by the `node` (main) process when it starts.
y
