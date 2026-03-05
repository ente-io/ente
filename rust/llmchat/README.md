# LLM Chat (Rust)

This directory contains the Rust crates for the Ensu LLM chat stack.

## Crates

- `db/` (`llmchat-db`) — local chat database.
- `sync/` (`llmchat-sync`) — sync engine (uses `llmchat-db`).
- `inference/` (`inference_rs`) — inference runtime.

## UniFFI bindings

UniFFI wrapper crates live under `uniffi/`:

- `uniffi/llmchat_db_uniffi`
- `uniffi/llmchat_sync_uniffi`
- `uniffi/inference_rs_uniffi`
