# Rust E2E

Rust end-to-end tests that require a live Museum instance belong here.

The single `full_e2e` test runs these stages in sequence:
`auth_contacts_e2e`, `legacy_contact_recovery_e2e`, and
`legacy_kit_recovery_e2e`.

Like the CLI integration tests, the suite runs against a live Museum spun up by
[ente-test-support](../crates/test-support) (see its README for setup). It is
gated behind Cargo features, so a plain `cargo test -p ente-e2e` skips it. To
run it:

```sh
cargo test -p ente-e2e --features museum,pglite
```

For ad hoc runs against an already-running server (skips the fixture):

```sh
ENTE_E2E_ENDPOINT=http://localhost:8080 cargo test -p ente-e2e --features museum,pglite -- --nocapture
```

To skip or select stages:

```sh
ENTE_E2E_SKIP=legacy_kit_recovery_e2e cargo test -p ente-e2e --features museum,pglite
ENTE_E2E_ONLY=legacy_contact_recovery_e2e cargo test -p ente-e2e --features museum,pglite
```
