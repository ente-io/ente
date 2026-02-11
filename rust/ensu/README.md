# LLM Chat (Rust)

This directory contains the Rust crates for the Ensu LLM chat stack.

## Crates

- `db/` (`llmchat-db`) — local chat database.
- `sync/` (`llmchat-sync`) — sync engine (uses `llmchat-db`).
- `inference/` (`inference_rs`) — inference runtime.

## UniFFI bindings

UniFFI wrapper crates live under `../uniffi/ensu/`:

- `../uniffi/ensu/db`
- `../uniffi/ensu/sync`
- `../uniffi/ensu/inference`
