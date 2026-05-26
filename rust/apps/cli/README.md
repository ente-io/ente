WIP Ente Rust CLI.

## Development

```sh
cargo run --bin ente-rs -- --help
```

## Integration tests

The integration tests spin up a local Museum server backed by an in-memory Postgres using [pglite](https://pglite.dev). These are gated behind Cargo features, so a plain `cargo test -p ente-rs` skips them.

One-time setup:

```sh
npm ci --prefix rust/apps/cli/tests/pglite
```

Run the tests from the `rust/` directory:

```sh
cargo test -p ente-rs --features museum,pglite
```
