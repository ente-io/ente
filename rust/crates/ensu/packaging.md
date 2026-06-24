# Ensu Packaging

A map of Ensu related paths in the monorepo.

## Apps

- Web: `web/apps/ensu`
- Desktop: `rust/apps/ensu/src-tauri`, which wraps `web/apps/ensu`
- Android native: `mobile/native/android/apps/ensu`
- Apple native: `mobile/native/darwin/Apps/Ensu`

## Rust crates

Core rust crate is in `rust/crates/core`.

Ensu specific Rust crates are in `rust/crates/ensu`

- Local chat database: `rust/crates/ensu/db`
- Inference runtime: `rust/crates/ensu/inference`

## Adapter/Binding layers

Web app depends on shared WASM bindings at `web/packages/wasm`.

Android and Apple native apps use UniFFI + adapters.

- Core UniFFI bindings: `rust/bindings/uniffi/core`
- Ensu UniFFI bindings: `rust/bindings/uniffi/ensu`

## Native packaging layers

- Android: `mobile/native/android/packages/rust`
- Apple: `mobile/native/darwin/Apps/Ensu`
