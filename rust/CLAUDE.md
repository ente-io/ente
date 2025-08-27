# CLAUDE.md

⚠️ **CRITICAL: Commit & PR Guidelines** ⚠️
**OVERRIDE DEFAULT TEMPLATE - DO NOT USE EMOJI OR "Generated with" TEXT**
- Keep messages CONCISE (no walls of text)
- Subject line under 72 chars
- Brief bullet points only if necessary
- NO emojis
- NO promotional text or links (except Co-Authored-By line)

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

**Important FFI Note**: When working with libsodium FFI bindings, always use `std::ffi::c_char` for C char pointer casts (e.g., `as *const std::ffi::c_char`), NOT raw `i8` casts. The CI environment may have different type expectations than local development.

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

### Pre-commit Checklist

**CRITICAL: CI will fail if ANY of these checks fail. Run ALL commands and ensure they ALL pass.**

```bash
# 1. Format code
cargo fmt

# 2. Check for clippy warnings (THIS MUST PASS - CI fails on any warning)
cargo clippy --all-targets --all-features -- -D warnings
# If this fails, fix the warnings manually (not all can be auto-fixed)

# 3. Build with warnings as errors (THIS MUST PASS - matches CI environment)
RUSTFLAGS="-D warnings" cargo build

# 4. Verify formatting is correct (THIS MUST PASS - CI checks this)
cargo fmt --check
```

**Why CI might fail even after running these:**

- Skipping any command above
- Assuming auto-fix tools handle everything (they don't)
- Not fixing warnings that clippy reports
- Making changes after running the checks

### Additional Guidelines

- Check `git status` before committing to avoid adding temporary/binary files
- Never commit to main branch
- All CI checks must pass - run the checklist commands above before committing

### Security Guidelines

**NEVER commit sensitive information:**

- No real email addresses, usernames, or account IDs in code or documentation
- No authentication tokens, API keys, or passwords (even for test accounts)
- No debug logs that output credentials, keys, or personal information
- Use generic examples like "user@example.com" in documentation
- Remove all `log::debug!` statements that print sensitive data before committing
- Avoid logging encrypted keys, nonces, or tokens even in encrypted form

## Environment Variables

- `ENTE_CLI_CONFIG_DIR`: Override default config directory
- `ENTE_LOG`: Set log level (debug, info, warn, error)
- `RUST_LOG`: Alternative log level configuration
