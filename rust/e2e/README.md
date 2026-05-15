# Rust E2E

Rust end-to-end tests that require a live Museum instance belong here.

Current server-backed coverage in this crate:

- ignored stage tests that reuse shared fixtures inside one test binary: `auth_contacts_e2e`, `legacy_contact_recovery_e2e`, and `legacy_kit_recovery_e2e`
- ignored paste CLI coverage: `paste_cli_e2e`

Detailed scenario coverage lives in [`COVERAGE.md`](COVERAGE.md).

Preferred local runner:

```sh
rust/e2e/scripts/run.sh
```

GitHub Actions uses the same runner via `.github/workflows/rust-e2e-test.yml`.

That runner:

- starts Museum in Docker with Postgres only
- enables deterministic OTT for `@ente-rust-test.org`
- defaults to `http://localhost:18080` to avoid colliding with an already running local Museum on `8080`
- waits for `GET /ping`
- builds the `ente-rs` CLI binary
- runs this crate's ignored tests

Paste CLI E2E can also run without Docker by using PGlite:

```sh
rust/e2e/scripts/run-pglite.sh
```

That runner:

- starts PGlite in memory through `@electric-sql/pglite-socket`
- starts Museum locally with DB settings pointed at PGlite
- builds the `ente-rs` CLI binary
- defaults `ENTE_E2E_ONLY` to `paste_cli_e2e`

For a compile-only sanity check that does not hit a live server:

```sh
cargo test --manifest-path rust/Cargo.toml -p ente-e2e
```

For ad hoc runs against an already-running server:

```sh
ENTE_E2E_ENDPOINT=http://localhost:8080 cargo test --manifest-path rust/Cargo.toml -p ente-e2e -- --ignored --nocapture
```

To run only one ignored stage:

```sh
ENTE_E2E_ENDPOINT=http://localhost:8080 cargo test --manifest-path rust/Cargo.toml -p ente-e2e legacy_kit_recovery_e2e -- --ignored --nocapture
```

For a paste CLI run against an already-running server, build the CLI and pass its path:

```sh
cargo build --manifest-path rust/Cargo.toml -p ente-rs --bin ente-rs
ENTE_E2E_ENDPOINT=http://localhost:8080 \
ENTE_E2E_CLI_BIN=rust/target/debug/ente-rs \
cargo test --manifest-path rust/Cargo.toml -p ente-e2e paste_cli_e2e -- --ignored --nocapture
```

To skip or select stages during a full ignored run:

```sh
ENTE_E2E_SKIP=legacy_kit_recovery_e2e rust/e2e/scripts/run.sh
ENTE_E2E_ONLY=legacy_contact_recovery_e2e rust/e2e/scripts/run.sh
```

Attachment/object-store coverage can be added as a separate fixture later, but it is intentionally not part of the baseline auth/recovery suite.
