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
│                           │ │                           │ │  (future: when CLI     │
│  Shared #[frb] wrappers   │ │  #[wasm_bindgen] wrappers │ │   uses ente-core)      │
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

```
rust/
├── src/                    # Existing CLI code (untouched until later)
│   └── main.rs
├── Cargo.toml              # Existing CLI Cargo.toml
│
└── core/                   # Pure Rust business logic
    ├── src/
    │   ├── lib.rs
    │   └── urls.rs
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
- `ente-wasm` - wasm-bindgen wrappers for web
- `ente_rust` - shared FRB wrappers for mobile (Dart class: `EnteRust`)
- `ente_photos_rust` - Photos app-specific FRB (Dart class: `EntePhotosRust`)

## Tooling

### [wasm-bindgen](https://github.com/wasm-bindgen/wasm-bindgen)

A Rust library that provides the `#[wasm_bindgen]` attribute macro. When you annotate a function with `#[wasm_bindgen]`, it:

1. Marks the function for export to JavaScript
2. Handles type conversions between Rust and JS (e.g., `String` ↔ JS string, `i64` ↔ `BigInt`)
3. Generates metadata that the wasm-bindgen CLI uses to create JS/TS glue code

The library itself is lightweight - just macros and runtime types.

### [wasm-pack](https://github.com/drager/wasm-pack)

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

## Future

### CLI Migration

When CLI should use ente-core:

1. Move `rust/src/` → `rust/cli/`
2. Create workspace `Cargo.toml` at `rust/`
3. CLI depends on ente-core
4. Gradually replace CLI's own implementations with ente-core calls

### WASM Compatibility

Core crate must handle deps that don't compile to WASM:

| Dependency             | Issue            | Solution                                                                                |
| ---------------------- | ---------------- | --------------------------------------------------------------------------------------- |
| `libsodium-sys-stable` | Native C library | Feature-gate; use pure Rust crypto (e.g., `chacha20poly1305` crate) or WebCrypto via JS |
| `rusqlite`             | Native SQLite    | Feature-gate; WASM uses IndexedDB via JS interop                                        |
| `tokio` (full)         | Threading        | Use WASM-compatible features only                                                       |
| Filesystem ops         | No FS in browser | Abstract behind traits                                                                  |

**Approach:** Cargo feature flags in ente-core?

```toml
[features]
default = ["native"]
native = ["libsodium-sys-stable", "rusqlite/bundled"]
wasm = ["getrandom/js"]
```

### Other notes

- Never panic across FFI boundary - always return Result or map errors
- Keep binding functions thin - logic belongs in ente-core
- Mobile binary size: LTO + symbol stripping

## Tests

- **ente-core:** Standard `cargo test` - comprehensive unit tests
- **ente_photos_rust:** Minimal FRB smoke test in Dart to catch binding drift
- **ente-wasm:** Vitest tests in web package
- **Golden fixtures:** Share test vectors across native/FRB/WASM for crypto parity
