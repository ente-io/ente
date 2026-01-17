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
│   │   └── main.rs
│   ├── Cargo.toml
│   └── Cargo.lock
│
└── core/                   # Pure Rust shared logic
    ├── src/
    │   ├── lib.rs
    │   ├── crypto/
    │   └── auth/
    ├── docs/
    │   ├── crypto.md
    │   └── auth.md
    └── Cargo.toml          # crate name: ente-core

web/packages/wasm/          # WASM bindings (lives in web workspace)
├── src/
│   └── lib.rs              # #[wasm_bindgen] wrappers around ente-core
├── Cargo.toml              # crate name: ente-wasm
├── package.json            # includes wasm-pack as devDependency
└── pkg/                    # generated output (gitignored)

mobile/packages/rust/       # Shared FRB bindings for all mobile apps
├── rust/
│   ├── src/
│   │   └── api/            # #[frb] wrappers around ente-core
│   └── Cargo.toml          # crate name: ente_rust
├── lib/                    # Generated Dart bindings
└── pubspec.yaml            # Flutter plugin package

mobile/apps/photos/rust/    # Photos app-specific FRB bindings
├── src/
│   ├── lib.rs
│   └── api/                # #[frb] app-specific code (usearch, ML)
│       └── *.rs
└── Cargo.toml              # crate name: ente_photos_rust
```

**Crates:**

- `ente-core` - shared business logic (pure Rust, no FFI)
  - Docs: `rust/core/docs/crypto.md`, `rust/core/docs/auth.md`
- `ente-wasm` - wasm-bindgen wrappers for web
- `ente_rust` - shared FRB wrappers for mobile (Dart class: `EnteRust`)
- `ente_photos_rust` - Photos app-specific FRB (Dart class: `EntePhotosRust`)

## Tooling

### [wasm-bindgen](https://github.com/rustwasm/wasm-bindgen)

A Rust library that provides the `#[wasm_bindgen]` attribute macro. When you annotate a function with `#[wasm_bindgen]`, it:

1. Marks the function for export to JavaScript
2. Handles type conversions between Rust and JS (e.g., `String` ↔ JS string, `i64` ↔ `BigInt`)
3. Generates metadata that the wasm-bindgen CLI uses to create JS/TS glue code

### [wasm-pack](https://github.com/rustwasm/wasm-pack)

A CLI tool that orchestrates the WASM build process:

1. Runs `cargo build --target wasm32-unknown-unknown`
2. Invokes `wasm-bindgen` CLI to generate JS/TS bindings from the compiled WASM
3. Outputs everything to a `pkg/` directory ready for npm/bundlers

wasm-pack is installed via npm as a devDependency, so `yarn install` handles it.

### [Flutter Rust Bridge (FRB)](https://github.com/fzyzcjy/flutter_rust_bridge)

Used for Flutter integration. FRB is used on two crates:

- **`ente_rust`** (`mobile/packages/rust/`) - Shared wrappers around `ente-core`, used by multiple mobile apps (Photos, Auth, etc.)
- **`ente_photos_rust`** (`mobile/apps/photos/rust/`) - Photos app-specific functionality (usearch, ML)

Both depend on `ente-core` and use `#[frb]` annotations to generate Dart bindings.

## Development

### Commands

**ente-core (rust/core/):**

```sh
cargo fmt        # format
cargo clippy     # lint
cargo build      # build
cargo test       # test
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
> cargo watch -w ../rust/core -w packages/wasm/src -s "yarn build:wasm"
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
