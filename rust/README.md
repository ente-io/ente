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
│  mobile/packages/rust/    │ │   web/packages/wasm/      │ │    rust/apps/cli/      │
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
│  Thin app-specific #[frb] │
│  wrappers for rust/photos │
└───────────────────────────┘
```

## Contents (this repo)

- `rust/crates/core/` (`ente-core`) - shared, pure Rust code used by clients (crypto + auth, plus small HTTP/URL helpers).
- `rust/photos/` (`ente_photos`) - shared Photos Rust logic (motion photo, ML, image processing, vector DB).
- `rust/apps/cli/` (`ente-rs`) - Rust CLI.
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
│   └── image/                    # Shared image crate
│
├── e2e/                          # Rust e2e tests requiring live Museum
│   ├── src/
│   │   └── lib.rs
│   ├── tests/
│   └── Cargo.toml
│
├── core/                         # Pure Rust shared logic (ente-core)
│   ├── src/
│   │   ├── lib.rs
│   │   ├── crypto/
│   │   └── auth/
│   ├── docs/
│   │   ├── crypto.md
│   │   └── auth.md
│   └── Cargo.toml
│
├── photos/                       # Shared Photos Rust logic
│   ├── src/
│   │   ├── lib.rs
│   │   ├── image/
│   │   ├── ml/
│   │   └── vector_db.rs
│   └── Cargo.toml
│
└── ensu/                         # LLM chat stack (see rust/crates/ensu/README.md)

rust/bindings/uniffi/                      # UniFFI bindings for core crypto/auth + ensu
├── core/
└── ensu/

web/packages/wasm/                # WASM bindings (lives in web workspace)
├── src/
│   └── lib.rs                    # #[wasm_bindgen] wrappers around ente-core
├── Cargo.toml                    # crate name: ente-wasm
├── package.json                  # includes wasm-pack as devDependency
└── pkg/                          # generated output (gitignored)

mobile/packages/rust/             # Shared FRB bindings for all mobile apps
├── rust/
│   ├── src/
│   │   └── api/                  # #[frb] wrappers around ente-core
│   └── Cargo.toml                # crate name: ente_rust
├── lib/                          # Generated Dart bindings
└── pubspec.yaml                  # Flutter plugin package

mobile/apps/photos/rust/          # Photos app-specific FRB bindings
├── src/
│   ├── lib.rs
│   └── api/                      # #[frb] thin wrappers over rust/photos
│       └── *.rs
└── Cargo.toml                    # crate name: ente_photos_rust
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

- **`ente_rust`** (`mobile/packages/rust/`) - Shared wrappers around `ente-core`, used by multiple mobile apps (Photos, Auth, etc.)
- **`ente_photos_rust`** (`mobile/apps/photos/rust/`) - Thin Photos-specific wrappers around `rust/photos`

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

**ente-wasm (web/packages/wasm/):**

```sh
yarn install     # installs wasm-pack
yarn build       # runs wasm-pack build --target bundler
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
> cargo watch -w ../rust/crates/core -w packages/wasm/src -s "yarn build:wasm"
> ```

**ente_rust (mobile/packages/rust/):**

```sh
cargo install flutter_rust_bridge_codegen
flutter_rust_bridge_codegen generate
```

`flutter_rust_bridge_codegen generate` needs to be run either manually (or in watch mode, `flutter_rust_bridge_codegen generate --watch`) whenever the Rust source changes to get the bindings to update.

**ente_photos_rust (mobile/apps/photos/rust/):**

```sh
flutter_rust_bridge_codegen generate
flutter test
```
