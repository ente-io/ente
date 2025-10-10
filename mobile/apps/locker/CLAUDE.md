# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Philosophy

Ente is focused on privacy, transparency and trust. It's a fully open-source, end-to-end encrypted platform for storing data in the cloud. When contributing, always prioritize:
- User privacy and data security
- End-to-end encryption integrity
- Transparent, auditable code
- Zero-knowledge architecture principles

## Project Overview

Ente Locker is a Flutter application for securely storing important documents. It's part of the Ente mobile monorepo and shares multiple packages with the Ente Photos app. The app provides encrypted file storage with collections, sharing capabilities, and cross-platform support (iOS, Android, Linux, Windows, macOS).

## Commit & PR Guidelines

⚠️ **CRITICAL: From the default template, use ONLY: Co-Authored-By: Claude <noreply@anthropic.com>** ⚠️

### Pre-commit/PR Checklist (RUN BEFORE EVERY COMMIT OR PR!)

**CRITICAL: CI will fail if ANY of these checks fail. Run ALL commands and ensure they ALL pass.**

```bash
# 1. Format Dart code
dart format .

# 2. Analyze flutter code for errors and warnings
flutter analyze
```

**Why CI might fail even after running these:**

- Skipping any command above
- Assuming auto-fix tools handle everything (they don't)
- Not fixing warnings that flutter reports
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

### Build & Run

```bash
# Install dependencies (from monorepo root /Users/amanraj/development/ente/mobile)
melos bootstrap

# Clean the locker app specifically
melos run clean:locker

# Run the app (from this directory)
flutter run

# Build for specific platforms
flutter build apk      # Android
flutter build ios      # iOS
flutter build macos    # macOS
flutter build windows  # Windows
flutter build linux    # Linux
```

### Code Quality

```bash
# Run linter
flutter analyze

# Auto-format code
dart format .

# Run lint on specific file
flutter analyze lib/path/to/file.dart
```

### Testing

There are currently no tests in the `test/` directory. When adding tests:
```bash
flutter test                    # Run all tests
flutter test test/path/to/file_test.dart  # Run specific test
```

## Architecture

### Monorepo Structure

Locker is one of multiple apps in `/apps/` that share common packages from `/packages/`:

**Shared Packages:**
- `ente_accounts` - User authentication and account management
- `ente_base` - Base utilities and common code
- `ente_configuration` - App configuration (extended by local `services/configuration.dart`)
- `ente_crypto_dart` - Encryption/decryption primitives
- `ente_events` - Event bus for app-wide events
- `ente_legacy` - Legacy services (e.g., emergency contacts)
- `ente_lock_screen` - App lock/authentication UI
- `ente_logging` - Structured logging
- `ente_network` - HTTP client and network layer
- `ente_sharing` - Sharing models and utilities
- `ente_strings` - Localization strings
- `ente_ui` - Common UI components and theming
- `ente_utils` - Platform utilities and helpers

### Core Services (Singletons)

All major services follow the singleton pattern with `instance` getters:

1. **CollectionService** (`lib/services/collections/collections_service.dart`)
   - Manages collections (folders) and files within them
   - Syncs with server and maintains local cache (`_collectionIDToCollections`)
   - Handles collection CRUD operations
   - Provides encryption key management for collections and files

2. **Configuration** (`lib/services/configuration.dart`)
   - Extends `BaseConfiguration` from `ente_configuration` package
   - Stores user settings, account info, and app state
   - Initialized with database instances in `main.dart`

3. **UserService** (from `ente_accounts`)
   - Manages user authentication and account details
   - Fires `SignedInEvent` and `SignedOutEvent` via event bus

4. **TrashService** (`lib/services/trash/trash_service.dart`)
   - Manages deleted files and trash operations

5. **LinksService** (`lib/services/files/links/links_service.dart`)
   - Handles shareable public links for collections

### Database Layer

SQLite databases managed via `sqflite`:
- **CollectionDB** (`lib/services/collections/collections_db.dart`) - Collections and files
- **TrashDB** (`lib/services/trash/trash_db.dart`) - Deleted items

Both databases track sync times to enable incremental syncing.

### Event-Driven Architecture

The app uses an event bus (`ente_events` package) for cross-component communication:

**Key Events:**
- `SignedInEvent` / `SignedOutEvent` - Authentication state changes
- `CollectionsUpdatedEvent` - Triggers UI refresh when collections change
- `BackupUpdatedEvent` - File upload progress/completion

**Pattern:** Services fire events, UI components listen and call `setState()`.

### UI Structure

**Main Pages:**
- `HomePage` - Main dashboard with collections grid, recents, and FAB
- `CollectionPage` - Single collection view with files
- `AllCollectionsPage` - Full collection list (by type: home/incoming/outgoing)
- `SettingsPage` - User settings and account management
- `InformationPage` - Add/edit structured information (notes, credentials, contacts, etc.)

**Key UI Patterns:**
- Pages extend `StatefulWidget` with mixins for reusable behavior (e.g., `SearchMixin`)
- `UploaderPage`/`UploaderPageState` - Base class for pages that handle file uploads
- Collections use `CollectionFlexGridView` for responsive grid layouts
- Search functionality integrated via `SearchMixin` with search bar in AppBar

### File Upload Flow

1. User selects file via `file_picker` package
2. `UploaderPage.uploadFiles()` picks collection (or creates one)
3. `FileUploadService` encrypts and uploads to server
4. `CollectionService.sync()` called to fetch updated state
5. `CollectionsUpdatedEvent` fired → UI refreshes

### Crypto & Encryption

Files and collections are end-to-end encrypted:
- **Collection keys:** Encrypted with user's master key
- **File keys:** Encrypted with collection key
- `CryptoHelper` (`utils/crypto_helper.dart`) provides key derivation utilities
- `ente_crypto_dart` provides low-level encryption primitives

### Platform-Specific Code

**Desktop (Windows/Linux/macOS):**
- Window management via `window_manager` package
- System tray support via `tray_manager` package
- Initialized in `main.dart` before `runApp()`

**Mobile (iOS/Android):**
- Share intent handling via `listen_sharing_intent` package
- `HomePage.initializeSharing()` processes shared files from other apps
- High refresh rate support on Android via `flutter_displaymode`

### Localization

- Uses Flutter's built-in `l10n` system
- Localization files in `lib/l10n/`
- Generated code via `flutter gen-l10n` (configured in `l10n.yaml`)
- Shared strings from `ente_strings` package
- Access in widgets via `context.l10n.keyName`

## Code Style & Linting

The project uses strict linting rules defined in `ente/mobile/analysis_options.yaml`:

**Key enforced rules:**
- `require_trailing_commas` (ERROR) - All function/constructor calls must have trailing commas
- `always_use_package_imports` (WARNING) - Use `package:` imports, not relative
- `prefer_final_fields` (ERROR) - Prefer `final` for non-reassigned fields
- `prefer_const_constructors` (WARNING) - Use `const` constructors where possible
- `unawaited_futures` (WARNING) - Explicitly handle or ignore futures
- `cancel_subscriptions` (ERROR) - Cancel StreamSubscriptions in `dispose()`
- `prefer_double_quotes` - Use double quotes for strings

**To fix trailing comma errors:** Run `dart format .` which auto-adds them.

## Important Patterns

### Service Initialization

Services are initialized in `main.dart` in a specific order:
1. Crypto initialization (`CryptoUtil.init()`)
2. Database initialization (CollectionDB, TrashDB)
3. Configuration with databases
4. Network layer
5. Service-specific initialization

### Sync Pattern

Many operations follow this pattern:
```dart
// 1. Call API
await _apiClient.someOperation(params);

// 2. Sync to update local state
await CollectionService.instance.sync();

// 3. Event bus notifies UI (optional, sync may fire it)
Bus.instance.fire(CollectionsUpdatedEvent());
```

**Important:** Avoid calling `setState()` or manual reloads after operations that trigger `sync()`, as the sync fires `CollectionsUpdatedEvent` which already refreshes the UI.

### File References

When referencing code locations in messages, use the format:
```
lib/services/collections/collections_service.dart:123
```

## Known TODOs

From README.md:
- Verify `PackageInfoUtil.getPackageName()` correctness on Linux and Windows
- Update `file_url.dart` to download only via CF worker when necessary

## Common Gotchas

1. **Multiple Flutter apps in monorepo:** Always use `melos bootstrap` instead of `flutter pub get` to properly link local packages
2. **Window management:** Desktop window initialization must happen before `runApp()` in `main.dart`
3. **Trailing commas:** The linter is strict about this - always add them to avoid CI failures
4. **Package imports:** Never use relative imports for files in other packages; always use `package:` syntax
5. **Sync timing:** File upload operations should NOT manually call `_loadCollections()` in the callback to avoid duplicate UI refreshes (see `HomePage.onFileUploadComplete()`)

## Critical Coding Requirements

### 1. Code Quality - MANDATORY
**Every code change MUST pass `dart format .` and `flutter analyze` with zero issues**
- Run `dart format .` first to format all Dart code
- Run `flutter analyze` after EVERY code modification
- Resolve ALL issues (info, warning, error) - no exceptions
- The codebase has zero issues by default, so any issue is from your changes
- DO NOT commit or consider work complete until both commands pass cleanly

### 2. Component Reuse - MANDATORY
**Always try to reuse existing components**
- Use a subagent to search for existing components before creating new ones
- Only create new components if none exist that meet the requirements
- Check both UI components in `lib/ui/` and shared components in `../../packages/`

### 3. Design System - MANDATORY
**Never hardcode colors or text styles**
- Always use the Ente design system for colors and typography
- Use a subagent to find the appropriate design tokens
- Access colors via theme: `getEnteColorScheme(context)`
- Access text styles via theme: `getEnteTextTheme(context)`
- Call above theme getters only at the top of (`build`) methods and re-use them throughout the component
- If you MUST use custom colors/styles (extremely rare), explicitly inform the user with a clear warning

### 4. Database Methods - BEST PRACTICE
**Prioritize readability in database methods**
- For small result sets (e.g., 1-2 stale entries), prefer filtering in Dart for cleaner, more readable code
- For large datasets, use SQL WHERE clauses for performance - they're much more efficient in SQLite
