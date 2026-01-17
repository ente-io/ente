# Rust in Ente

This directory hosts Rust crates used across Ente clients.

## Crates

### `rust/core/` (ente-core)

Pure Rust shared logic (primarily cryptography) that is wire-compatible with the existing
JS/Dart implementations.

- Source: `rust/core/src/`
- Docs:
  - `rust/core/docs/crypto.md`

## Development

**ente-core (rust/core/):**

```sh
cargo fmt
cargo clippy
cargo build
cargo test
```

## Integrations

- Web (wasm-bindgen): `web/packages/wasm/` wraps `ente-core` for web apps.
- Mobile (FRB): `mobile/packages/rust/` wraps `ente-core` for Flutter apps.

## CLI (added in a follow-up PR)

A Rust CLI lives in `rust/cli/` and will depend on `ente-core`.

## Validation + Fuzzing (added in a follow-up PR)

Validation suite + benchmarks (vs libsodium) and fuzz targets will live under:
- `rust/validation/`
- `rust/core/fuzz/`
