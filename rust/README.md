# Rust in Ente

```
                         ┌───────────────────────────────────────┐
                         │            rust/crates/core/                 │
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
│ rust/bindings/frb/        │ │ rust/bindings/wasm/      │ │    rust/apps/cli/      │
│ ente-rust/                │ │ ente-wasm/               │ │                        │
│    (ente_rust crate)      │ │    (ente-wasm crate)     │ │                        │
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
│ rust/bindings/frb/photos/ │
│  (ente_photos_rust crate) │
│                           │
│  Thin app-specific #[frb] │
│ wrappers for crates/photos │
└───────────────────────────┘
```

## Contents (this repo)

- `rust/crates/core/` (`ente-core`) - shared, pure Rust code used by clients (crypto + auth, plus small HTTP/URL helpers).
- `rust/crates/photos/` (`ente_photos`) - shared Photos Rust logic (motion photo, ML, image processing, vector DB).
- `rust/apps/cli/` (`ente-rs`) - Rust CLI.
- `rust/bindings/frb/ente-rust/` (`ente_rust`) - shared Flutter Rust Bridge bindings for mobile.
- `rust/bindings/frb/photos/` (`ente_photos_rust`) - Photos app-specific Flutter Rust Bridge bindings.
- `rust/bindings/wasm/ente-wasm/` (`ente-wasm`) - wasm-bindgen bindings for web.
- `rust/e2e/` (`ente-e2e`) - live Museum-backed Rust end-to-end tests.
- `rust/crates/ensu/` - LLM chat stack (see `rust/crates/ensu/README.md`).

## Directory Structure

```
rust/
├── apps/
│   ├── cli/                      # CLI package (ente-rs)
│   │   ├── src/
│   │   │   └── main.rs
│   │   └── Cargo.toml
│   │
│   └── codegen/                  # Cargo-powered repo codegen helper
│       ├── src/
│       └── Cargo.toml
│
├── crates/
│   ├── accounts/                 # Shared account helpers
│   ├── contacts/                 # Shared contacts logic
│   ├── core/                     # Pure Rust shared logic (ente-core)
│   ├── ensu/                     # LLM chat stack
│   ├── image/                    # Shared image crate
│   └── photos/                   # Shared Photos Rust logic
│
├── e2e/                          # Rust e2e tests requiring live Museum
│   ├── src/
│   │   └── lib.rs
│   ├── tests/
│   └── Cargo.toml
│
└── Cargo.toml                    # Rust workspace manifest

rust/bindings/uniffi/                      # UniFFI bindings for core crypto/auth + ensu
├── core/
└── ensu/

rust/bindings/frb/                         # Flutter Rust Bridge binding crates
├── ente-rust/
│   ├── src/
│   │   └── api/                  # #[frb] wrappers around ente-core
│   └── Cargo.toml                # crate name: ente_rust
└── photos/
    ├── src/
    │   └── api/                  # #[frb] thin wrappers over rust/crates/photos
    └── Cargo.toml                # crate name: ente_photos_rust

rust/bindings/wasm/ente-wasm/     # WASM bindings Rust crate
├── src/
│   └── lib.rs                    # #[wasm_bindgen] wrappers around ente-core
└── Cargo.toml                    # crate name: ente-wasm

web/packages/wasm/                # JS package surface for ente-wasm
├── package.json                  # includes wasm-pack as devDependency
└── pkg/                          # generated output (gitignored)

mobile/packages/rust/             # Shared FRB bindings for all mobile apps
├── lib/                          # Generated Dart bindings
└── pubspec.yaml                  # Flutter plugin package
```

**Crates:**

- `ente-core` - shared business logic (pure Rust, no FFI)
  - Docs: `rust/crates/core/docs/crypto.md`, `rust/crates/core/docs/auth.md`
- `ente_photos` - shared Photos Rust logic
- `ente-rs` - Rust CLI package (`ente-cli` binary)
- `ente-e2e` - ignored Rust integration tests that run against a live Museum
- `ente-wasm` - wasm-bindgen wrappers for web
- `ente_rust` - shared FRB wrappers for mobile (Dart class: `EnteRust`)
- `ente_photos_rust` - Photos app-specific FRB (Dart class: `EntePhotosRust`)

## Tooling

### [wasm-bindgen](https://github.com/wasm-bindgen/wasm-bindgen)

A Rust library that provides the `#[wasm_bindgen]` attribute macro. When you annotate a function with `#[wasm_bindgen]`, it:

1. Marks the function for export to JavaScript
2. Handles type conversions between Rust and JS (e.g., `String` ↔ JS string, `i64` ↔ `BigInt`)
3. Generates metadata that the wasm-bindgen CLI uses to create JS/TS glue code

### [wasm-pack](https://github.com/drager/wasm-pack)

A CLI tool that orchestrates the WASM build process:

1. Runs `cargo build --target wasm32-unknown-unknown`
2. Invokes `wasm-bindgen` CLI to generate JS/TS bindings from the compiled WASM
3. Outputs everything to a `pkg/` directory ready for npm/bundlers

wasm-pack is installed via npm as a devDependency, so `yarn install` handles it.

### [Flutter Rust Bridge (FRB)](https://github.com/fzyzcjy/flutter_rust_bridge)

Used for Flutter integration. FRB is used on two crates:

- **`ente_rust`** (`rust/bindings/frb/ente-rust/`) - Shared wrappers around `ente-core`, used by multiple mobile apps (Photos, Auth, etc.)
- **`ente_photos_rust`** (`rust/bindings/frb/photos/`) - Thin Photos-specific wrappers around `rust/crates/photos`

Both depend on `ente-core` and use `#[frb]` annotations to generate Dart bindings.

## Development

### Commands

**ente-core (rust/crates/core/):**

```sh
cargo fmt        # format
cargo clippy     # lint
cargo build      # build
cargo test       # test
```

**ente-cli (rust/apps/cli/):**

```sh
cargo fmt        # format
cargo clippy     # lint
cargo build      # build
cargo test       # test
cargo run --bin ente-cli -- --help
```

**ente-e2e (rust/e2e/):**

```sh
cargo test --manifest-path rust/Cargo.toml -p ente-e2e             # compile-only sanity check
rust/e2e/scripts/run.sh                                            # starts Docker + runs ignored live suite
cargo test --manifest-path rust/Cargo.toml -p ente-e2e -- --ignored --nocapture
```

**ente-wasm (Rust source in rust/bindings/wasm/ente-wasm/, JS package in web/packages/wasm/):**

```sh
yarn install     # installs wasm-pack
yarn build       # runs wasm-pack against the Rust crate
```

Or from web/ root:

```sh
yarn build:wasm  # builds the WASM package
```

> [!TIP]
>
> For active Rust development, use watch mode in a separate terminal:
>
> ```sh
> cargo install cargo-watch
> cd web/
> cargo watch -w ../rust/crates/core -w ../rust/bindings/wasm/ente-wasm/src -s "yarn build:wasm"
> ```

**Generated bindings:**

```sh
cd rust
cargo codegen native
cargo codegen frb
```

`native` regenerates the UniFFI bindings used by native mobile apps.
`frb` regenerates both `ente_rust` and `ente_photos_rust`.
