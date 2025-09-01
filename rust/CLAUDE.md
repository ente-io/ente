# CLAUDE.md

## Commit & PR Guidelines

⚠️ **CRITICAL: From the default template, use ONLY: Co-Authored-By: Claude <noreply@anthropic.com>** ⚠️

### Pre-commit/PR Checklist (RUN BEFORE EVERY COMMIT OR PR!)

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

### Commit & PR Message Rules

**These rules apply to BOTH commit messages AND pull request descriptions**

- Keep messages CONCISE (no walls of text)
- Subject line under 72 chars (no body text unless critical)
- NO emojis
- NO promotional text or links (except Co-Authored-By line)

### Additional Guidelines

- Check `git status` before committing to avoid adding temporary/binary files
- Never commit to main branch
- All CI checks must pass - run the checklist commands above before committing or creating PR

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

CLI for ente.io with end-to-end encryption, multi-account and multi-app support.

### Core Modules

**`api/`** - HTTP client for ente.io API

- `client.rs`: Base HTTP client with auth token management
- `auth.rs`: SRP (Secure Remote Password) authentication implementation
- `methods.rs`: API method implementations (collections, files, user info)
- `models.rs`: API request/response data structures
- `retry.rs`: Retry logic with exponential backoff for rate limiting

**`crypto/`** - Cryptographic operations using libsodium

- `argon.rs`: Argon2id key derivation
- `chacha.rs`: ChaCha20-Poly1305 encryption/decryption
- `stream.rs`: XChaCha20-Poly1305 streaming decryption for large files
- `kdf.rs`: Blake2b key derivation
- All crypto MUST use `libsodium-sys-stable` (statically linked)

**`storage/`** - SQLite persistence layer

- `schema.rs`: Database schema for accounts, files, collections
- `account.rs`: Account CRUD operations with multi-app support
- `sync.rs`: Sync state management (last sync times, file tracking)
- `config.rs`: Key-value configuration store
- Uses `rusqlite` with bundled SQLite for portability

**`cli/`** - Command-line argument parsing

- `account.rs`: Account command argument structures
- `export.rs`: Export command argument structures
- `version.rs`: Version information constants
- Uses `clap` for argument parsing

**`commands/`** - Command implementation logic

- `account.rs`: Account management implementation (add, list, update, get-token)
- `export.rs`: Photo export orchestration with filtering support
- `sync.rs`: Synchronization logic execution

**`models/`** - Data structures

- `account.rs`: Account model with encrypted credentials
- `file.rs`: File metadata and encryption info
- `collection.rs`: Albums/collections with sharing support
- `metadata.rs`: Decrypted file metadata (title, timestamps, location)
- `filter.rs`: Export filtering options (shared/hidden albums, emails)
- `error.rs`: Error types using `thiserror`

**`sync/`** - Synchronization engine

- `engine.rs`: Core sync orchestration and state management
- `files.rs`: File synchronization logic
- `download.rs`: File download and decryption implementation

**`utils/`** - Utility functions

- `mod.rs`: Config directory management with platform-specific defaults

### Key Implementation Details

1. **Authentication Flow**: SRP-based authentication storing tokens in SQLite, supports multiple apps (photos, locker, auth)
2. **Multi-Account Support**: SQLite-based storage with per-account/per-app token management
3. **File Organization**: Export to `export_dir/AlbumName/filename` structure (files in "Uncategorized" if no album)
4. **Export Filtering**: Support for filtering by shared/hidden albums and specific user emails
5. **Encryption**: Files encrypted with ChaCha20-Poly1305, streaming decryption for large files, keys derived via Argon2/Blake2b
6. **Async Runtime**: Uses tokio with full features for concurrent operations
7. **Error Handling**: Propagate errors with `?` operator, use `anyhow` for context
8. **Configuration**: Platform-specific config directories (Linux: ~/.config/ente-cli, macOS: ~/Library/Application Support/ente-cli, Windows: %APPDATA%/ente-cli)

## Security Guidelines

**NEVER commit sensitive information:**

- No real email addresses, usernames, or account IDs in code or documentation
- No authentication tokens, API keys, or passwords (even for test accounts)
- No debug logs that output credentials, keys, or personal information
- Use generic examples like "user@example.com" in documentation
- Remove all `log::debug!` statements that print sensitive data before committing
- Avoid logging encrypted keys, nonces, or tokens even in encrypted form

## Environment Variables

- `ENTE_CLI_CONFIG_DIR`: Override default config directory
- `RUST_LOG`: Set log level (debug, info, warn, error, trace)
