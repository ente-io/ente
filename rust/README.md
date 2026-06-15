# Rust

Cargo workspace for Ente's Rust code.

## Development

```sh
cargo fmt        # Format
cargo clippy     # Lint
cargo build      # Build
cargo test       # Test

cargo run --bin ente-rs -- --help   # Run the Ente Rust CLI
```

CI runs with `RUSTFLAGS="-D warnings"` so warnings will cause checks to fail.

Other useful commands:

```sh
cargo codegen native  # Regenerate bindings used by native apps
cargo codegen frb     # Regenerate bindings used by Flutter apps

# E2E tests against a local Museum (see e2e/README.md for setup)
cargo test -p ente-e2e --features museum
```
