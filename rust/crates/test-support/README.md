# ente-test-support

A test fixture that runs a local Museum backed by in-memory Postgres
([pglite](https://pglite.dev)), used by the `ente-rs` and `ente-e2e` integration
tests.

## Setup

Requires `go` and `node` on PATH. Install the pglite dependency once:

```sh
npm ci --prefix rust/crates/test-support/pglite
```

## Usage

Tests that use the fixture are gated behind the `museum` and `pglite` Cargo
features, so a plain `cargo test` skips them:

```sh
cargo test -p ente-e2e --features museum,pglite
```
