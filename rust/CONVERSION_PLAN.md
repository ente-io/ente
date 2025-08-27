# Ente CLI Rust Conversion Plan

## Current Status
The Rust CLI has achieved **feature parity with the Go CLI for photos app** core functionality! Export, sync, and incremental updates are fully working with proper file decryption, metadata handling, progress indicators, and deduplication.

### ✅ Photos App Core Features - COMPLETE
- **Export**: Full workflow with decryption, metadata, deduplication, live photos
- **Sync**: Full and incremental sync with downloads, progress tracking
- **Account**: Multi-account support with SRP authentication
- **Storage**: SQLite with efficient schema and indexing
- **Crypto**: All encryption/decryption working (Argon2, XChaCha20-Poly1305, XSalsa20-Poly1305)

### 📝 Photos App Remaining Features
- Export filters (by album, date range, shared/hidden)
- Resume interrupted downloads
- EXIF/location data preservation
- Thumbnail generation
- Album symlinks

### ❌ Not Planned (Auth App Features)
- Locker export
- 2FA/Auth export
These features are specific to the auth app and not needed for photos functionality.

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
- ✅ **Public magic metadata support for renamed files**
- ✅ Create date-based directory structure (YYYY/MM-Month/)
- ✅ Skip already exported files (local deduplication)
- ✅ **Hash-based deduplication to prevent duplicate exports**
- ✅ **Live photo extraction from ZIP archives**
- ✅ Progress indicators with file counts and progress bars
- ✅ Export summary with statistics

### Account Management (`/rust/src/commands/account.rs`)
- ✅ **Account list** - Display all configured accounts
- ✅ **Account add** - Full SRP authentication implemented
- ✅ Store encrypted credentials in SQLite
- ✅ 2FA/OTP support
- ✅ Proper key derivation with Argon2

### Metadata Handling (`/rust/src/models/metadata.rs`, `/rust/src/models/file.rs`)
- ✅ **Metadata decryption and parsing**
- ✅ Extract original filenames
- ✅ File type detection (Image, Video, LivePhoto)
- ✅ Public magic metadata support for renamed files
- ✅ Edited name prioritization (public magic metadata → regular metadata)

## Recently Completed 🎉

### Sync Command (`/rust/src/commands/sync.rs`) - ✅ COMPLETE
- ✅ **Full sync workflow implemented**
- ✅ Metadata-only mode for fast syncing
- ✅ Full mode with file downloads
- ✅ Per-collection incremental sync tracking
- ✅ Store sync state in SQLite
- ✅ Handle deleted files/collections
- ✅ **Integrated file downloads with progress indicators**
- ✅ Hash-based deduplication during downloads
- ✅ Correct counting logic for new/updated/deleted items

### File Download Manager (`/rust/src/sync/download.rs`) - ✅ COMPLETE
- ✅ Download individual files with decryption
- ✅ Parallel download infrastructure (tokio tasks)
- ✅ **Progress bars using indicatif**
- ✅ **Live photo extraction from ZIP archives**
- ✅ Proper error handling and retry logic
- ✅ Memory-efficient streaming downloads
- ✅ Hash-based deduplication

## Remaining Components 📝

### Database and Storage (`/rust/src/storage/`) - ✅ COMPLETE
- ✅ **Platform-specific config directory** (`~/.config/ente-cli/`)
- ✅ Avoid conflicts with Go CLI path
- ✅ SQLite schema with proper foreign keys
- ✅ Collections and files storage
- ✅ Per-collection sync state tracking
- ✅ Content hash storage for deduplication
- ✅ Efficient indexes for lookups

### Account Management Enhancements
- [ ] **Account remove** - Delete account and credentials
- [ ] **Token refresh** - Handle expired tokens

### Advanced Export Features
- [ ] Export filters (by album, date range)
- [ ] Shared album support
- [ ] Hidden album handling
- ✅ **Live photos (ZIP file extraction)** - Implemented
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
- ✅ **Duplicate detection by hash** - Implemented with SHA-512

### Download Manager Enhancements
- ✅ **Parallel downloads** - Using tokio tasks
- [ ] Resume interrupted downloads
- [ ] Bandwidth throttling
- ✅ **Progress tracking per file** - Using indicatif progress bars
- [ ] Temp file management

## Testing Status 🧪

### Successfully Tested ✅
- ✅ Export with real account
- ✅ Small file decryption (JPEG images)
- ✅ Large file decryption (33MB RAW file)
- ✅ Metadata extraction for filenames
- ✅ Public magic metadata for renamed files
- ✅ Date-based directory creation
- ✅ File deduplication (local and hash-based)
- ✅ Incremental sync (per-collection)
- ✅ Live photo extraction from ZIP
- ✅ Progress indicators during downloads
- ✅ Hash-based duplicate detection

### Manual Testing Checklist
- [x] Can export from existing Ente account
- [x] Lists all albums/collections correctly
- [x] Downloads files to correct folder structure (YYYY/MM-Month/)
- [x] Correctly decrypts files
- [x] Extracts original filenames from metadata
- [x] Handles renamed files from public magic metadata
- [x] Sync command fetches collections and files
- [x] Metadata-only sync mode works
- [x] Full sync mode with file downloads
- [x] Database stored in ~/.config/ente-cli/
- [x] Handles incremental sync (only new files)
- [x] Hash-based deduplication prevents duplicates
- [x] Live photos extracted correctly
- [x] Progress bars show download progress
- [ ] Resumes interrupted downloads
- [ ] Multi-account export works
- [ ] Export filters (by album, date range) work

## Migration from Go CLI

### Feature Parity Progress (Photos App)
- [x] Multi-account support (storage)
- [x] Photos export (complete with all features)
- [x] Sync command (full implementation with downloads)
- [x] Album organization
- [x] Deduplicated storage (hash-based)
- [x] Platform-specific config paths
- [x] SRP authentication (fully implemented)
- [x] Full sync with file downloads
- [x] Incremental sync (per-collection tracking)
- [x] Public magic metadata support
- [x] Live photo extraction
- [x] Progress indicators
- [ ] Export filters (albums, shared, hidden)
- [ ] Shared album support

### Not Planned (Auth App Features)
- [ ] Locker export (auth app)
- [ ] Auth (2FA) export (auth app)

### Data Migration
- [ ] BoltDB to SQLite migration tool
- [ ] Preserve sync state
- [ ] Migrate account credentials

## Recent Achievements 🎉

1. **Full Sync Implementation with Downloads**
   - Complete sync engine with per-collection tracking
   - Incremental sync with proper timestamp management
   - Integrated file downloads with progress bars
   - Hash-based deduplication prevents duplicate downloads
   - Live photo extraction from ZIP archives

2. **Public Magic Metadata Support**
   - Handles renamed files correctly
   - Prioritizes edited names over original names
   - Decrypts both regular and public magic metadata

3. **Progress Indicators**
   - Download progress bars using indicatif
   - Real-time status updates during sync
   - Accurate counting of new/updated/deleted items

4. **Hash-Based Deduplication**
   - SHA-512 content hashing for files
   - Prevents duplicate exports across collections
   - Efficient database indexing for hash lookups
   - Tested and verified with duplicate files

## Next Actions 🚀

### Photos App - Remaining Features

1. **Export Filters**
   - Filter by album/collection name
   - Filter by date range
   - Export only specific albums
   - Support for shared albums
   - Support for hidden albums

2. **Resume Capability**
   - Track partially downloaded files
   - Resume interrupted downloads
   - Verify partial file integrity

3. **Advanced Features**
   - Thumbnail generation
   - EXIF data preservation
   - Location data handling
   - Creation/modification time preservation
   - Symlink creation for album organization

4. **Performance Optimizations**
   - Connection pooling for API requests
   - Bandwidth throttling options
   - Configurable parallel download limits
   - Memory usage optimization for large exports

### Infrastructure Improvements

1. **Error Handling**
   - Retry logic with exponential backoff
   - Better rate limiting (429 handling)
   - Graceful recovery from network errors

2. **Account Management**
   - Account remove command
   - Token refresh mechanism
   - Multiple endpoint support

3. **Data Migration**
   - BoltDB to SQLite migration tool
   - Preserve sync state during migration
   - Account credential migration

## Environment Variables
- `ENTE_CLI_CONFIG_DIR` - Override config directory location
- `ENTE_LOG` / `RUST_LOG` - Set log level (debug, info, warn, error)

## Key Implementation Notes
1. **Crypto**: Successfully using libsodium-sys-stable for all operations
2. **Streaming**: Proper streaming XChaCha20-Poly1305 implementation
3. **Storage**: SQLite working well for account and credential storage
4. **Async**: Tokio runtime properly configured
5. **Memory**: Chunked processing prevents memory issues with large files