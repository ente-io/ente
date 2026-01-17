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

## Contents (this repo)

- `rust/core/` (`ente-core`) - shared, pure Rust code used by clients (crypto + auth, plus small HTTP/URL helpers).
- `rust/cli/` - Rust CLI (work-in-progress).

## Directory Structure

```
rust/
├── cli/                    # CLI package
│   ├── src/
│   └── Cargo.toml
└── core/                   # Pure Rust business logic
    ├── src/
    ├── docs/
    └── Cargo.toml          # crate name: ente-core
```

## Development

**ente-core (rust/core/):**

```sh
cargo fmt
cargo clippy
cargo build
cargo test
```

See `rust/core/README.md` for module docs.
