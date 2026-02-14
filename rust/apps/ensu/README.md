# Ensu Tauri

This wraps the **Ensu web app** in a Tauri shell for maximum component reuse.

## Dev

```bash
cd rust/apps/ensu
# runs the Ensu web dev server and launches Tauri (default port 3010)
yarn dev
```

To change the dev port:

```bash
cd rust/apps/ensu
ENSU_TAURI_PORT=3020 yarn dev
```

## Build

```bash
cd rust/apps/ensu
# builds the Ensu web app and exports a static build for Tauri
yarn build
```

## Notes
- The Tauri build uses the Ensu web app at `web/apps/ensu`.
- Static export is enabled only when `ENTE_TAURI=1`.
