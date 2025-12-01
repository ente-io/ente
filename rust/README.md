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
│ mobile/apps/photos/rust/  │ │  web/packages/ente-wasm/  │ │      rust/cli/         │
│                           │ │     (ente-wasm crate)     │ │                        │
│ Depends on ente-core      │ │                           │ │  (future: when CLI     │
│ #[frb] wrappers inline    │ │  Rust crate + wasm-pack   │ │   uses ente-core)      │
│ + app-specific (usearch)  │ │  #[wasm_bindgen] wrappers │ │                        │
└───────────────────────────┘ └───────────────────────────┘ └────────────────────────┘
              │                            │
              ▼                            ▼
┌───────────────────────────┐ ┌───────────────────────────┐
│   Flutter Photos App      │ │        Web Apps           │
│                           │ │   (Photos, Auth, etc.)    │
└───────────────────────────┘ └───────────────────────────┘
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

web/packages/ente-wasm/     # WASM bindings (lives in web workspace)
├── src/
│   └── lib.rs              # #[wasm_bindgen] wrappers around ente-core
├── Cargo.toml              # crate name: ente-wasm
├── package.json            # includes wasm-pack as devDependency
└── pkg/                    # generated output (gitignored)

mobile/apps/photos/rust/    # FRB bindings (lives in mobile app)
├── src/
│   ├── lib.rs
│   └── api/                # #[frb] wrappers around ente-core
│       └── *.rs
└── Cargo.toml              # crate name: rust_lib_photos
```

**Crates:**

- `ente-core` - shared business logic (pure Rust, no FFI)
- `ente-wasm` - wasm-bindgen wrappers for web
- `rust_lib_photos` - FRB wrappers for mobile

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

Used for Flutter integration. FRB wrappers (annotated with `#[frb]`) live in `mobile/apps/photos/rust/` and depend on `ente-core`.

Currently, App-specific functionality (usearch, ML) stays alongside in the same crate. In the future, if another one of Ente's Flutter apps needs the same wrappers, we can extract a shared crate.

## Development

### Commands

**ente-core (rust/core/):**

```sh
cargo fmt        # format
cargo clippy     # lint
cargo build      # build
cargo test       # test
```

**ente-wasm (web/packages/ente-wasm/):**

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

**rust_lib_photos (mobile/apps/photos/rust/):**

One time:

```sh
cargo install flutter_rust_bridge_codegen
```

From `mobile/apps/photos`:

```sh
flutter pub get
flutter_rust_bridge_codegen generate
```

Then `mobile/apps/photos/rust/`

```sh
cargo build
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
- **rust_lib_photos:** Minimal FRB smoke test in Dart to catch binding drift
- **ente-wasm:** Vitest tests in web package
- **Golden fixtures:** Share test vectors across native/FRB/WASM for crypto parity
