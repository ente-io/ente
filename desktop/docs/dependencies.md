# Dependencies

See [web/docs/dependencies.md](../../web/docs/dependencies.md) for general web
specific dependencies. See [electron.md](electron.md) for our main dependency,
Electron. The rest of this document describes the remaining, desktop specific
dependencies that are used by the Photos desktop app.

## Electron related

### next-electron-server

This spins up a server for serving files using a protocol handler inside our
Electron process. This allows us to directly use the output produced by
`next build` for loading into our renderer process.
