# ente-test-support

Runs a local Museum backed by a temporary Postgres
([postgresql_embedded](https://crates.io/crates/postgresql_embedded)) for the
`ente-rs` and `ente-e2e` integration tests.

## Setup

Requires `go` on PATH (to build and run Museum). The Postgres binary is
downloaded and cached automatically on first use.

## Usage

Tests that use it are gated behind the `museum` Cargo feature, so a plain
`cargo test` skips them:

```sh
cargo test -p ente-e2e --features museum
```
