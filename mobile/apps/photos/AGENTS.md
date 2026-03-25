# Ente Photos Mobile App Agent Guidelines

This file provides guidance for AI coding agents working on the Ente Photos mobile application.

## Project Overview

Ente is a monorepo containing multiple interconnected components. The Photos app is a Flutter application for photo management and backup with end-to-end encryption, ML-powered features, and cross-platform support.

## Project Philosophy

Ente is focused on privacy, transparency and trust. It's a fully open-source, end-to-end encrypted platform for storing data in the cloud. When contributing, always prioritize:
- User privacy and data security
- End-to-end encryption integrity
- Transparent, auditable code
- Zero-knowledge architecture principles

Protect user privacy and preserve end-to-end encryption integrity in every change. Keep implementations transparent and auditable to sustain user trust. Design with zero-knowledge architecture assumptions so sensitive data never leaves the user's control.

## Build, Lint & Test Commands

### Mobile Apps (Flutter/Dart)

```bash
# Install dependencies
flutter pub get

# Development run
./run.sh                                    # Uses .env file with --flavor dev

# Alternative development run
flutter run -t lib/main.dart --flavor independent

# Build release APK
flutter build apk --release --flavor independent

# Code quality
flutter analyze .    # Static analysis
dart format .        # Code formatting
flutter test         # Run tests
```

### Running Single Tests

```bash
# Run specific test
flutter test test/path/to/test.dart
```

## Code Style Guidelines

### Dart (Mobile Apps)

- **Formatting**: 2-space indentation with trailing commas
- **Naming**: snake_case for files, PascalCase for classes, camelCase for methods
- **Imports**: Always use package imports (`package:ente/...`)
- **Error Handling**: Use proper exception handling, avoid print statements
- **State Management**: Follow existing service locator pattern

## Monorepo Context

This Photos app lives inside the Ente monorepo alongside Auth, Locker, web, desktop, CLI, and backend code. Shared Flutter packages sit under `mobile/packages/`; Photos-specific Flutter plugins live in `mobile/apps/photos/plugins/`.

This is the Ente Photos mobile app within the Ente monorepo. The monorepo contains:
- Mobile apps (Photos, Auth, Locker) at `mobile/apps/`
- Shared packages at `mobile/packages/`
- Web, desktop, CLI, and server components in parent directories

### Package Architecture
The Photos app uses two types of packages:
- **Shared packages** (`../../packages/`): Common code shared across multiple Ente apps (Photos, Auth, Locker)
- **Photos-specific plugins** (`./plugins/`): Custom Flutter plugins specific to Photos app for separation and testability

## Project Structure & Module Organization

`lib/` houses the Flutter client (`core/`, `services/`, `ui/`, `db/`). Tests live in `test/` (unit & widget) and `integration_test/`. Platform shells are `android/` and `ios/`; Rust crates and bridge helpers sit in `rust/` and `rust_builder/`. Assets, fonts, and localization configs are in `assets/`, `fonts/`, `l10n.yaml`, with generated code in `lib/generated/`. Automation scripts include `scripts/`, `run.sh`, `build-apk.sh`, and release tooling under `fastlane/`.

```
lib/
├── core/           # Configuration, constants, networking
├── services/       # Business logic (28+ services)
├── ui/            # UI components (18 subdirectories)
├── models/        # Data models (17 subdirectories)
├── db/            # SQLite database layer
├── utils/         # Utilities and helpers
├── gateways/      # API gateway interfaces
├── events/        # Event system
├── l10n/          # Localization files (intl_*.arb)
└── generated/     # Auto-generated code including localizations
```

## Build, Test & Development Commands

Run `flutter pub get` after dependency edits. Launch the dev flavor via `./run.sh` (reads `.env`) or use `flutter run -t lib/main.dart --flavor independent`. Regenerate Rust bindings with `flutter_rust_bridge_codegen generate` before builds. Android releases rely on `flutter build apk --release --flavor independent`; for iOS run `cd ios && pod install` then `flutter build ios`. Use `./build-apk.sh` when Gradle artifacts from `thirdparty/transistor-background-fetch` need refreshing.

### Using Melos (Monorepo Management)
```bash
# From mobile/ directory - bootstrap all packages
melos bootstrap

# Run Photos app specifically
melos run:photos:apk

# Build Photos APK
melos build:photos:apk

# Clean Photos app
melos clean:photos
```

### Direct Flutter Commands
```bash
# Development run with environment variables
./run.sh                                    # Uses .env file with --flavor dev

# Development run without env file
flutter run -t lib/main.dart --flavor independent

# Build release APK
flutter build apk --release --flavor independent

# iOS build
cd ios && pod install && cd ..
flutter build ios
```

### Code Quality
```bash
# Static analysis and linting
flutter analyze .

# Run tests
flutter test
```

## Coding Style & Naming Conventions

Use 2-space indentation and format with `dart format .` (trailing commas preserved). `analysis_options.yaml` enforces rules such as `prefer_const_constructors`, `require_trailing_commas`, and `always_use_package_imports`. Keep files `snake_case.dart`, classes `PascalCase`, private members `_camelCase`. Avoid `print`; rely on the log utilities under `lib/core/`.

## Testing Guidelines

Mirror source names with `*_test.dart`. Run only suites that cover your changes—`flutter test` (or a filtered target) when relevant tests exist, and skip it if no tests touch your work. Device flows stay in `integration_test/` (`flutter test integration_test`). Rust-facing updates should extend coverage with `cargo test` plus Dart adapter checks. Document new fixtures or goldens in `docs/`.

## Commit & Pull Request Guidelines

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

Commits should stay concise and imperative, summarising all substantial code changes. PR titles must tag the scope: `[mob][photos] …` for this app, else `[mob][auth]`, `[mob][locker]`, `[mob][packages]`, `[web]`, `[desktop]`, `[server]`, `[infra]`, or package-specific tags like `[mob][native_video_editor]`. Use `.github/pull_request_template.md` as your outline. Populate the Tests section with Markdown checkboxes covering only the validations needed pre-merge (keep it tight, relevant, and ≤5 items); omit the entire section when nothing needs to run. Add QA notes and UI captures when applicable, and verify `flutter analyze .` plus only the applicable tests from above before submitting.

## Rust & Localization Notes

Regenerate Dart bindings when Rust APIs change and keep generated code in `lib/src/rust/`. Exercise Rust crates with `cargo test` during such updates. For copy edits, update `lib/l10n/intl_en.arb` then run `flutter gen-l10n` (configured by `l10n.yaml`) to refresh `lib/generated/`, and coordinate Crowdin syncs through `crowdin.yml`.

## Localization (Flutter)

- Add new strings to `lib/l10n/intl_en.arb` (English base file)
- Use `AppLocalizations` to access localized strings in code
- Example: `AppLocalizations.of(context).yourStringKey`
- Run code generation after adding new strings: `flutter pub get`
- Translations managed via Crowdin for other languages

## Key Dependencies

- **Flutter 3.32.8** with Dart SDK >=3.3.0 <4.0.0
- **Media**: `photo_manager`, `video_editor`, `ffmpeg_kit_flutter`
- **Storage**: `sqlite_async`, `flutter_secure_storage`
- **ML/AI**: Custom ONNX runtime, `ml_linalg`
- **Rust**: Flutter Rust Bridge for performance

## Development Setup Requirements

1. Install Flutter `3.32.8` with a Dart SDK between `>=3.3.0 <4.0.0`.
2. Install Rust along with `flutter_rust_bridge_codegen` via `cargo install flutter_rust_bridge_codegen`.
3. Regenerate Rust bindings whenever native APIs shift using `flutter_rust_bridge_codegen generate`.
4. Initialize and refresh git submodules with `git submodule update --init --recursive`.
5. Point git hooks at the repository hooks directory: `git config core.hooksPath hooks`.

## Architecture Overview

### Service-Oriented Architecture
The app uses a service layer pattern with 28+ specialized services:
- **collections_service.dart**: Album and collection management
- **search_service.dart**: Search functionality with ML support
- **smart_memories_service.dart**: AI-powered memory curation
- **sync_service.dart**: Local/remote synchronization
- **Machine Learning Services**: Face recognition, semantic search, similar images

### Key Patterns
- **Service Locator**: Dependency injection via `lib/service_locator.dart`
- **Event Bus**: Loose coupling via `lib/core/event_bus.dart`
- **Repository Pattern**: Database abstraction in `lib/db/`
- **Rust Integration**: Performance-critical operations via Flutter Rust Bridge

### Security Architecture
- End-to-end encryption with `ente_crypto` package
- BIP39 mnemonic-based key generation (24 words)
- Secure storage using platform-specific implementations
- App lock and privacy screen features

## Critical Practices

- `dart format .` must run before you commit so the tree stays uniformly formatted.
- Follow each edit with `flutter analyze` and resolve every warning or info message introduced by the change.
- Reuse existing UI and service components; search both `lib/ui/` and `../../packages/` before creating new primitives.
- Respect the design system—pull colors from `getEnteColorScheme(context)` and text styles from `getEnteTextTheme(context)`, caching the theme at the top of `build`.
- Keep specs and docs in sync with code updates; when behavior shifts, revise the relevant files under `docs/` or adjacent directories.

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

### 4. Documentation Sync - MANDATORY
**Keep spec documents synchronized with code changes**
- When modifying code, also update any associated spec documents
- Check for related spec files in `docs/` or project directories
- Ensure documentation reflects the current implementation
- Update examples in specs if behavior changes

### 5. Database Methods - BEST PRACTICE
**Prioritize readability in database methods**
- For small result sets (e.g., 1-2 stale entries), prefer filtering in Dart for cleaner, more readable code
- For large datasets, use SQL WHERE clauses for performance - they're much more efficient in SQLite

## Important Notes

- Large service files (some 70k+ lines) - consider file context when editing
- 400+ dependencies - check existing libraries before adding new ones
- When adding functionality, check both `../../packages/` for shared code and `./plugins/` for Photos-specific plugins
- Performance-critical paths use Rust integration
- Always follow existing code conventions and patterns in neighboring files

# Individual Preferences
- @~/.claude/ente-photos-instructions.md