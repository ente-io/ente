# Ente CLI Rust Conversion Plan

## Current Status
The Rust CLI now has a **fully functional export capability** with proper file decryption! The API client, authentication flow (using stored credentials), and streaming decryption are all working. Files can be successfully exported from Ente with their original names.

## Completed Components ✅

### Core Infrastructure
- ✅ Project structure and dependencies (libsodium-sys-stable for crypto)
- ✅ SQLite storage layer with schema for accounts, files, collections
- ✅ Data models (Account, File, Collection, Error types)
- ✅ CLI command structure (account, export, version commands)

### Cryptography Module (`/rust/src/crypto/`)
- ✅ Argon2 key derivation (`argon.rs`)
- ✅ Blake2b login key derivation (`kdf.rs`)
- ✅ XSalsa20-Poly1305 (secret_box) for key decryption (`chacha.rs`)
- ✅ **Streaming XChaCha20-Poly1305** for file decryption (`stream.rs`)
- ✅ Chunked decryption for large files (4MB chunks)
- ✅ libsodium initialization and helpers

### API Client (`/rust/src/api/`)
- ✅ **Base HTTP client with token management** (`client.rs`)
- ✅ **Request/Response models** (`models.rs`)
  - ✅ Collection models
  - ✅ File models with metadata
  - ✅ User and auth response models
- ✅ **Core API methods** (`methods.rs`)
  - ✅ `get_collections()` - Fetch collections
  - ✅ `get_collection_files()` - Fetch files with pagination
  - ✅ `download_file()` - Download encrypted files

### Export Command (`/rust/src/commands/export.rs`)
- ✅ **Full export workflow implemented**
- ✅ Load stored credentials from SQLite
- ✅ Decrypt collection keys using master key
- ✅ Decrypt file keys using collection keys
- ✅ Decrypt file data using streaming XChaCha20-Poly1305
- ✅ Decrypt and parse metadata for original filenames
- ✅ Create date-based directory structure (YYYY/MM-Month/)
- ✅ Skip already exported files (deduplication)
- ✅ Progress indicators with file counts
- ✅ Beautiful export summary with emojis

### Account Management (`/rust/src/commands/account.rs`)
- ✅ **Account list** - Display all configured accounts
- ✅ **Account add** (partial) - Add account with stored credentials
- ✅ Store encrypted credentials in SQLite

### Metadata Handling (`/rust/src/models/metadata.rs`)
- ✅ **Metadata decryption and parsing**
- ✅ Extract original filenames
- ✅ File type detection (Image, Video, LivePhoto)
- ✅ Public metadata support

## In Progress 🚧

### Authentication Module (`/rust/src/api/auth.rs`)
- ⚠️ Currently using stored tokens (not implementing full SRP flow yet)
- Need to implement:
  - Full SRP authentication flow
  - Password-based key derivation
  - Token refresh logic

## Remaining Components 📝

### Account Management Enhancements
- [ ] **Account add with authentication**
  - Prompt for password
  - Perform SRP authentication
  - Derive and store keys
- [ ] **Account update** - Change export directory
- [ ] **Account remove** - Delete account and credentials

### Sync Engine (`/rust/src/sync/`)
- [ ] Fix model mismatches in sync modules
- [ ] Implement incremental sync with timestamps
- [ ] Store sync state in SQLite
- [ ] Handle deleted files/collections
- [ ] Track download progress

### Advanced Export Features
- [ ] Export filters (by album, date range)
- [ ] Shared album support
- [ ] Hidden album handling
- [ ] Live photos (ZIP file extraction)
- [ ] Thumbnail generation
- [ ] Export to different formats

### API Client Enhancements
- [ ] Retry logic with exponential backoff
- [ ] Rate limiting (429 status codes)
- [ ] Request/response logging
- [ ] Error recovery
- [ ] Connection pooling

### File Processing
- [ ] EXIF data extraction
- [ ] Location data handling
- [ ] Creation/modification time preservation
- [ ] Symlink creation for albums
- [ ] Duplicate detection by hash

### Download Manager
- [ ] Parallel downloads
- [ ] Resume interrupted downloads
- [ ] Bandwidth throttling
- [ ] Progress tracking per file
- [ ] Temp file management

## Testing Status 🧪

### Successfully Tested ✅
- ✅ Export with real account (m@ente.io)
- ✅ Small file decryption (JPEG images)
- ✅ Large file decryption (33MB RAW file)
- ✅ Metadata extraction for filenames
- ✅ Date-based directory creation
- ✅ File deduplication

### Manual Testing Checklist
- [x] Can export from existing Ente account
- [x] Lists all albums/collections correctly
- [x] Downloads files to correct folder structure (YYYY/MM-Month/)
- [x] Correctly decrypts files
- [x] Extracts original filenames from metadata
- [ ] Handles incremental sync (only new files)
- [ ] Resumes interrupted downloads
- [ ] Multi-account export works
- [ ] Export filters (by album, date range) work

## Migration from Go CLI

### Feature Parity Progress
- [x] Multi-account support (storage)
- [x] Photos export (basic)
- [ ] SRP authentication (using stored tokens currently)
- [ ] Locker export
- [ ] Auth (2FA) export
- [x] Album organization
- [x] Deduplicated storage
- [ ] Incremental sync
- [ ] Export filters (albums, shared, hidden)

### Data Migration
- [ ] BoltDB to SQLite migration tool
- [ ] Preserve sync state
- [ ] Migrate account credentials

## Recent Achievements 🎉

1. **Streaming XChaCha20-Poly1305 Implementation**
   - Correctly implemented libsodium's secretstream API
   - Matches Go implementation exactly
   - Handles both small and large files

2. **Chunked Decryption for Large Files**
   - 4MB chunk size matching Go implementation
   - Successfully tested with 33MB RAW files
   - Memory efficient processing

3. **Complete Export Flow**
   - Collection key decryption (XSalsa20-Poly1305)
   - File key decryption (XSalsa20-Poly1305)
   - File data decryption (Streaming XChaCha20-Poly1305)
   - Metadata decryption and parsing

## Next Actions 🚀

1. **Fix sync module compilation issues**
   - Resolve model mismatches between API and storage types
   - Implement proper sync state tracking

2. **Implement full SRP authentication**
   - Add password prompt to account add
   - Implement SRP protocol
   - Store derived keys securely

3. **Add export filters**
   - Filter by album name
   - Filter by date range
   - Handle shared/hidden albums

4. **Improve error handling**
   - Better error messages for users
   - Retry failed downloads
   - Handle network interruptions

## Environment Variables
- `ENTE_CLI_CONFIG_DIR` - Override config directory location
- `ENTE_LOG` / `RUST_LOG` - Set log level (debug, info, warn, error)

## Key Implementation Notes
1. **Crypto**: Successfully using libsodium-sys-stable for all operations
2. **Streaming**: Proper streaming XChaCha20-Poly1305 implementation
3. **Storage**: SQLite working well for account and credential storage
4. **Async**: Tokio runtime properly configured
5. **Memory**: Chunked processing prevents memory issues with large files