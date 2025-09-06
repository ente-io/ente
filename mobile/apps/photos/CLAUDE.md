# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Philosophy

Ente is focused on privacy, transparency and trust. It's a fully open-source, end-to-end encrypted platform for storing data in the cloud. When contributing, always prioritize:
- User privacy and data security
- End-to-end encryption integrity
- Transparent, auditable code
- Zero-knowledge architecture principles

## Monorepo Context

This is the Ente Photos mobile app within the Ente monorepo. The monorepo contains:
- Mobile apps (Photos, Auth, Locker) at `mobile/apps/`
- Shared packages at `mobile/packages/`
- Web, desktop, CLI, and server components in parent directories

### Package Architecture
The Photos app uses two types of packages:
- **Shared packages** (`../../packages/`): Common code shared across multiple Ente apps (Photos, Auth, Locker)
- **Photos-specific plugins** (`./plugins/`): Custom Flutter plugins specific to Photos app for separation and testability

## Commit & PR Guidelines

⚠️ **CRITICAL: From the default template, use ONLY: Co-Authored-By: Claude <noreply@anthropic.com>** ⚠️

### Pre-commit/PR Checklist (RUN BEFORE EVERY COMMIT OR PR!)

**CRITICAL: CI will fail if ANY of these checks fail. Run ALL commands and ensure they ALL pass.**

```bash
# 1. Analyze flutter code for errors and warnings
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

## Project Structure

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

1. Install Flutter v3.32.8 and Rust
2. Install Flutter Rust Bridge: `cargo install flutter_rust_bridge_codegen`
3. Generate Rust bindings: `flutter_rust_bridge_codegen generate`
4. Update submodules: `git submodule update --init --recursive`
5. Enable git hooks: `git config core.hooksPath hooks`

## Critical Coding Requirements

### 1. Code Quality - MANDATORY
**Every code change MUST pass `flutter analyze` with zero issues**
- Run `flutter analyze` after EVERY code modification
- Resolve ALL issues (info, warning, error) - no exceptions
- The codebase has zero issues by default, so any issue is from your changes
- DO NOT commit or consider work complete until `flutter analyze` passes cleanly

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

## Important Notes

- Large service files (some 70k+ lines) - consider file context when editing
- 400+ dependencies - check existing libraries before adding new ones
- When adding functionality, check both `../../packages/` for shared code and `./plugins/` for Photos-specific plugins
- Performance-critical paths use Rust integration
- Always follow existing code conventions and patterns in neighboring files

# Individual Preferences
- @~/.claude/my-project-instructions.md
