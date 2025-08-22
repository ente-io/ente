# Ente CLI Rust Conversion Plan

## Current Status
The foundation is complete with crypto, storage, and CLI framework. The next critical step is implementing the API client to enable authentication and data sync.

## Completed Components
- ✅ Project structure and dependencies (libsodium-sys-stable for crypto)
- ✅ Cryptography module (Argon2, ChaCha20-Poly1305, Blake2b KDF)
- ✅ SQLite storage layer with schema for accounts, files, collections
- ✅ Data models (Account, File, Collection, Error types)
- ✅ CLI command structure (account, export, version commands)

## Immediate Next Step: API Client Implementation

### 1. API Client Base Structure (`/rust/src/api/client.rs`)
**Current State**: Stub with basic struct definition
**To Do**:
- Add token storage HashMap for multi-account support
- Implement request builder with common headers (X-Auth-Token, X-Client-Package)
- Add retry logic with exponential backoff for failed requests
- Implement debug/trace logging for requests/responses
- Add rate limiting handling (429 status codes)

### 2. Request/Response Models (`/rust/src/api/models.rs`)
Create structs matching the Go implementation:
- `SrpAttributes` - For SRP auth setup (srpUserID, srpSalt, memLimit, opsLimit, kekSalt)
- `CreateSrpSessionRequest/Response` - SRP session creation
- `VerifySrpSessionRequest/Response` - SRP verification
- `AuthResponse` - Final auth response with token and key attributes
- `GetFilesRequest/Response` - File listing with pagination
- `GetCollectionsResponse` - Collections/albums listing
- `GetDiffResponse` - For incremental sync

### 3. Authentication Module (`/rust/src/api/auth.rs`)
Implement the complete SRP authentication flow:
- `get_srp_attributes(email)` - Get SRP params for user
- `create_srp_session(srp_user_id, client_pub)` - Start SRP
- `verify_srp_session(srp_user_id, session_id, client_proof)` - Complete SRP
- Key derivation from password using stored Argon2 params
- Login key derivation using Blake2b KDF
- Token extraction and storage

### 4. API Methods (`/rust/src/api/methods.rs`)
Core API endpoints to implement:
- `get_user_details()` - Fetch user info
- `get_collections(since_time)` - Fetch collections with changes
- `get_files(limit, since_time)` - Fetch file metadata
- `get_diff(since_time, limit)` - Get incremental changes
- `get_file_url(file_id)` - Get download URL for file
- `get_thumbnail_url(file_id)` - Get thumbnail URL

## Remaining Major Components

### 5. Account Management Commands (`/rust/src/commands/account.rs`)
**account add**:
- Prompt for email and password
- Perform SRP authentication
- Decrypt and store master key, secret key, token
- Prompt for export directory
- Save account to SQLite

**account list**:
- Query all accounts from SQLite
- Display email, app type, export directory

**account update**:
- Update export directory for existing account
- Validate directory exists and is writable

### 6. Sync Engine (`/rust/src/sync/engine.rs`)
Core sync logic:
- Fetch remote collections and store in SQLite
- Fetch remote files with pagination (500 per batch)
- Track sync state with timestamps
- Handle deleted files/collections
- Implement incremental sync using diff API

### 7. File Processing (`/rust/src/sync/files.rs`)
- Decrypt file metadata using collection keys
- Extract file creation time, location, type
- Build local file path based on date/album structure
- Check if file already exists locally (deduplication)
- Queue files for download

### 8. Download Manager (`/rust/src/sync/download.rs`)
- Fetch file download URL from API
- Download encrypted file to temp location
- Decrypt file using file key (decrypt with ChaCha20-Poly1305)
- Move to final location with proper filename
- Handle resume for partial downloads
- Parallel downloads with configurable concurrency

### 9. Export Command (`/rust/src/commands/export.rs`)
Main export workflow:
- Load all configured accounts
- For each account:
  - Load stored credentials
  - Initialize API client with token
  - Run sync engine
  - Download new/modified files
  - Create album folders and symlinks
  - Update sync timestamps

### 10. Metadata Handling (`/rust/src/models/metadata.rs`)
- Parse encrypted metadata JSON
- Extract EXIF data (camera, location, timestamp)
- Handle live photos (pair image + video)
- Extract and apply file creation/modification times

## Testing Strategy

### Unit Tests
- Crypto operations (compare outputs with Go implementation)
- Storage layer CRUD operations
- API request/response serialization

### Integration Tests
- Full authentication flow with test account
- File download and decryption
- Sync state management

### Manual Testing Checklist
- [ ] Can authenticate with existing Ente account
- [ ] Lists all albums/collections correctly
- [ ] Downloads files to correct folder structure (YYYY/MM-Month/)
- [ ] Handles incremental sync (only new files)
- [ ] Resumes interrupted downloads
- [ ] Multi-account support works
- [ ] Export filters (by album, date range) work

## Migration from Go CLI

### Data Migration
- BoltDB to SQLite migration tool (optional, for existing users)
- Preserve sync state to avoid re-downloading everything
- Migrate account credentials (re-encrypt with user confirmation)

### Feature Parity Checklist
- [ ] SRP authentication
- [ ] Multi-account support  
- [ ] Photos export
- [ ] Locker export
- [ ] Auth (2FA) export
- [ ] Album organization
- [ ] Deduplicated storage
- [ ] Incremental sync
- [ ] Export filters (albums, shared, hidden)

## File Structure Reference

```
/home/m/p/ente/rust/src/
├── api/
│   ├── mod.rs
│   ├── client.rs      # HTTP client with retry/auth
│   ├── models.rs      # Request/response structs
│   ├── auth.rs        # SRP authentication
│   └── methods.rs     # API endpoint implementations
├── commands/
│   ├── mod.rs
│   ├── account.rs     # Account management
│   └── export.rs      # Export orchestration
├── sync/
│   ├── mod.rs
│   ├── engine.rs      # Sync orchestration
│   ├── files.rs       # File processing
│   └── download.rs    # Download management
└── models/
    └── metadata.rs    # Metadata parsing

```

## Key Implementation Notes

1. **Crypto**: All crypto operations MUST use libsodium-sys-stable
2. **Errors**: Use proper error propagation with `?` operator
3. **Async**: Use tokio for all async operations
4. **Storage**: All persistent data goes through SQLite
5. **Memory**: Use `zeroize` for sensitive data cleanup
6. **Compatibility**: Ensure file paths work on Windows/Mac/Linux

## Environment Variables
- `ENTE_CLI_CONFIG_DIR` - Override config directory location
- `ENTE_LOG` - Set log level (debug, info, warn, error)

## Dependencies to Watch
- `libsodium-sys-stable` - Must match crypto operations with Go version
- `rusqlite` - Bundled SQLite for portability
- `reqwest` - Configure with proper timeouts and retry
- `tokio` - Use current_thread runtime for CLI app

## Next Action
Start with implementing the API client base structure in `/rust/src/api/client.rs`, focusing on:
1. Token management for multi-account
2. Request builder with proper headers
3. Error handling for API responses
4. Retry logic for network failures

This will unblock the authentication flow and allow testing with real Ente servers.