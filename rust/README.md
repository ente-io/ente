# Rust in Ente

```
                         ┌───────────────────────────────────────┐
                         │            rust/core/                 │
                         │        (ente-core crate)              │
                         │                                       │
                         │   Pure Rust - NO FFI annotations      │
                         │   Stateless business logic            │
                         │   Fully testable with cargo test      │
                         └───────────────────────────────────────┘
                                           │
              ┌────────────────────────────┼────────────────────────────┐
              │                            │                            │
              ▼                            ▼                            ▼
┌───────────────────────────┐ ┌───────────────────────────┐ ┌────────────────────────┐
│  mobile/packages/rust/    │ │   web/packages/wasm/      │ │      rust/cli/         │
│    (ente_rust crate)      │ │    (ente-wasm crate)      │ │                        │
│                           │ │                           │ │  CLI binary, depends   │
│  Shared #[frb] wrappers   │ │  #[wasm_bindgen] wrappers │ │  on ente-core          │
│  for all mobile apps      │ │  for all web apps         │ │                        │
└───────────────────────────┘ └───────────────────────────┘ └────────────────────────┘
         │    │                            │
         │    └──────────────┐             │
         ▼                   ▼             ▼
┌─────────────────┐   ┌────────────┐   ┌───────────────────────────┐
│   Photos App    │   │ Other apps │   │        Web Apps           │
│                 │   │ (Auth ...) │   │   (Photos, Auth, etc.)    │
└─────────────────┘   └────────────┘   └───────────────────────────┘
         ▲
         │
┌───────────────────────────┐
│ mobile/apps/photos/rust/  │
│  (ente_photos_rust crate) │
│                           │
│  App-specific #[frb]:     │
│  usearch, ML, etc.        │
└───────────────────────────┘
```

## Directory Structure

Rust crates live under `rust/`.

```
rust/
├── cli/                    # CLI package
│   ├── src/
│   │   └── main.rs
│   ├── Cargo.toml
│   └── Cargo.lock
│
└── core/                   # Pure Rust shared logic
    ├── src/
    ├── docs/
    └── Cargo.toml          # crate name: ente-core
```

Related integrations (outside this folder):

- `web/packages/wasm/` - WASM bindings around `ente-core` (`ente-wasm`)
- `mobile/packages/rust/` - Flutter Rust Bridge bindings around `ente-core` (`ente_rust`)
- `mobile/apps/photos/rust/` - Photos app-specific Rust crate (`ente_photos_rust`)

## Crates

- `ente-core` (`rust/core`) - shared crypto + auth helpers
  - Docs:
    - `rust/core/docs/crypto.md`
    - `rust/core/docs/auth.md`
- `ente-rs` (`rust/cli`) - Rust CLI
- `ente-wasm` (`web/packages/wasm`) - wasm-bindgen wrapper for web
- `ente_rust` (`mobile/packages/rust`) - shared FRB wrapper for mobile
- `ente_photos_rust` (`mobile/apps/photos/rust`) - Photos-specific FRB crate

## Tooling

### wasm-bindgen

`#[wasm_bindgen]` exports Rust APIs to JavaScript and handles type conversions.

### wasm-pack

Build helper for WASM crates. In this repo it’s used via the web workspace scripts.

### Flutter Rust Bridge (FRB)

Used for Flutter integration. The FRB crates wrap `ente-core` and generate Dart bindings.

## Development

**ente-core (rust/core/):**

```sh
cargo fmt
cargo clippy
cargo build
cargo test
```

**ente-rs (rust/cli/):**

```sh
cargo test
cargo run -- --help
```
