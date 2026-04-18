# Rust E2E

Rust end-to-end tests that require a live Museum instance belong here.

Current server-backed coverage in this crate:

- a single ignored full e2e suite that reuses one owner/trusted pair and covers
  auth, contacts CRUD, and the legacy recovery lifecycle

Detailed scenario coverage lives in [`COVERAGE.md`](COVERAGE.md).

Preferred local runner:

```sh
rust/e2e/scripts/run.sh
```

GitHub Actions uses the same runner via
`.github/workflows/rust-e2e-test.yml`.

That runner:

- starts Museum in Docker with Postgres only
- enables deterministic OTT for `@ente-rust-test.org`
- defaults to `http://localhost:18080` to avoid colliding with an already
  running local Museum on `8080`
- waits for `GET /ping`
- runs this crate's ignored tests

For a compile-only sanity check that does not hit a live server:

```sh
cargo test --manifest-path rust/e2e/Cargo.toml
```

For ad hoc runs against an already-running server:

```sh
ENTE_E2E_ENDPOINT=http://localhost:8080 cargo test --manifest-path rust/e2e/Cargo.toml -- --ignored --nocapture
```

Attachment/object-store coverage can be added as a separate fixture later, but
it is intentionally not part of the baseline auth/recovery suite.
