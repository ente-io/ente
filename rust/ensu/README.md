# LLM Chat (Rust)

This directory contains the Rust crates for the Ensu LLM chat stack.

For the current Ensu packaging map, see [`packaging.md`](packaging.md).

## Crates

- `db/` (`ensu-db`) — local chat database.
- `sync/` (`ensu-sync`) — sync engine (uses `ensu-db`).
- `inference/` (`inference_rs`) — inference runtime.

## UniFFI bindings

UniFFI wrapper crates live under `../uniffi/ensu/`:

- `../uniffi/ensu/db`
- `../uniffi/ensu/sync`
- `../uniffi/ensu/inference`
