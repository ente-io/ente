# CLAUDE.md

## Development Commands

### Build and Test
```bash
# Format code (required before commits)
cargo fmt

# Run linter (must pass for CI)
cargo clippy --all-targets --all-features

# Build the project
cargo build

# Run in development
cargo run -- <command>

# Build release version
cargo build --release
```

### CI Requirements
The codebase must pass the GitHub Actions workflow at `../.github/workflows/rust-lint.yml` which runs:
1. `cargo fmt --check` - Code formatting check
2. `cargo clippy --all-targets --all-features` - Linting with all warnings as errors (RUSTFLAGS: -D warnings)
3. `cargo build` - Build verification

## Architecture Overview

This is a Rust CLI for ente.io, providing encrypted photo backup and export functionality. The project is migrating from a Go implementation and follows a modular architecture:

### Core Modules

**`api/`** - HTTP client for ente.io API
- `client.rs`: Base HTTP client with auth token management
- Authentication uses SRP (Secure Remote Password) protocol
- Handles retry logic and rate limiting

**`crypto/`** - Cryptographic operations using libsodium
- `argon.rs`: Argon2id key derivation
- `chacha.rs`: ChaCha20-Poly1305 encryption/decryption
- `kdf.rs`: Blake2b key derivation
- All crypto MUST use `libsodium-sys-stable` (statically linked)

**`storage/`** - SQLite persistence layer
- `schema.rs`: Database schema for accounts, files, collections
- `account.rs`: Account CRUD operations
- `sync.rs`: Sync state management
- Uses `rusqlite` with bundled SQLite for portability

**`cli/`** - Command-line interface
- `account.rs`: Account management (add, list, update)
- `export.rs`: Photo export orchestration
- Uses `clap` for argument parsing

**`models/`** - Data structures
- `account.rs`: Account model with encrypted credentials
- `file.rs`: File metadata and encryption info
- `collection.rs`: Albums/collections
- `error.rs`: Error types using `thiserror`

**`sync/`** - Synchronization engine
- Handles incremental sync with ente servers
- File download and decryption
- Collection management

### Key Implementation Details

1. **Authentication Flow**: SRP-based authentication storing tokens in SQLite
2. **Multi-Account Support**: HashMap-based token storage per account
3. **File Organization**: Export to `YYYY/MM-Month/` directory structure
4. **Encryption**: All files encrypted with ChaCha20-Poly1305, keys derived via Argon2/Blake2b
5. **Async Runtime**: Uses tokio with full features
6. **Error Handling**: Propagate errors with `?` operator, use `anyhow` for context

## Current Status

The project has completed foundational components (crypto, storage, models) and is currently implementing the API client for authentication and sync. See `CONVERSION_PLAN.md` for detailed implementation roadmap.

## Commit Guidelines

- No promotional text like "Generated with [tool name]" - only keep the co-author line
- Check `git status` before committing to avoid adding temporary/binary files
- Never commit to main branch
- Ensure code passes `cargo fmt` and `cargo clippy` before committing

## Environment Variables

- `ENTE_CLI_CONFIG_DIR`: Override default config directory
- `ENTE_LOG`: Set log level (debug, info, warn, error)
- `RUST_LOG`: Alternative log level configuration
