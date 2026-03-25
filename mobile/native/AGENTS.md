# Ente Native Mobile Apps Agent Guidelines

This file provides guidance for AI coding agents working on Ente's native mobile applications (Android/iOS).

## Project Overview

Ente is a monorepo containing multiple interconnected components:
- **Native Android**: Kotlin/Gradle apps in `android/apps/ensu`
- **Native iOS/macOS**: Swift/Swift Package Manager in `darwin/`
- **Shared components**: Rust integration and cross-platform logic

## Project Structure & Module Organization
- `android/apps/ensu`: Android app workspace (Gradle Kotlin DSL). Key modules include `app-ui`, `domain`, `data`, `crypto-auth-core`, and `rust`.
- `android/packages/rust`: Shared Rust/Android integration module referenced by the app workspace.
- `darwin/Apps/ensu` and `darwin/Apps/tv`: Xcode projects for Apple platforms.
- `darwin/Packages/*`: Swift Package Manager libraries. Source code under `Sources/`, tests under `Tests/`.

## Build, Lint & Test Commands

### Android (Kotlin/Gradle)

```bash
# Build debug APK
cd android/apps/ensu && ./gradlew assembleDebug

# Run unit tests
cd android/apps/ensu && ./gradlew test

# Run specific test
./gradlew :module:test --tests "*TestName*"
```

### iOS/macOS (Swift/SwiftPM)

```bash
# Open in Xcode
open darwin/Apps/ensu/ensu.xcodeproj
open darwin/darwin.xcworkspace

# Run Swift package tests
swift test --package-path darwin/Packages/EnteCore

# Run specific test
swift test --package-path darwin/Packages/EnteCore --filter TestName
```

## Code Style Guidelines

### Kotlin (Android)
- **Formatting**: 4-space indentation, standard Kotlin conventions
- **Naming**: camelCase for variables/functions, PascalCase for types
- **Imports**: Organize with proper grouping
- **Error Handling**: Use proper exception handling patterns
- **Architecture**: Follow MVVM/clean architecture patterns

### Swift (iOS/macOS)
- **Formatting**: 4-space indentation, standard Swift conventions
- **Naming**: camelCase for members, PascalCase for types
- **Imports**: Use proper module imports
- **Error Handling**: Use Swift error handling patterns (do-catch, Result types)
- **Architecture**: Follow SwiftUI patterns and Combine for reactive programming

## Commit Guidelines

- Keep messages concise (< 72 chars)
- Subject line only (no body text)
- No emojis, no promotional text
- Format: `[mob] Add feature X to component Y`
- Run all lint/format checks before committing

## Testing Philosophy

- Write tests for new features and bug fixes
- Prefer unit tests over integration tests when possible
- Use meaningful test names that describe behavior
- Mock external dependencies appropriately
- Swift packages use `XCTest`; place tests in `darwin/Packages/*/Tests`
- Name tests by behavior (e.g., `TokenRefreshTests`, `RefreshTokenSucceedsWhenExpired`)
- Prefer focused unit tests per module; add integration tests in app targets as needed

## Architecture Principles

### Security First
- End-to-end encryption integrity is paramount
- Never compromise user privacy
- Validate all inputs, especially cryptographic operations
- Use secure random number generation

### Code Reuse
- Check existing packages before creating new code
- Shared logic belongs in appropriate packages

## Development Workflow

1. **Before starting**: Understand the component you're working on
2. **During development**: Run lint checks frequently
3. **Before commit**: Run full quality checks
4. **Testing**: Ensure tests pass and add new tests as needed

## Configuration & Security Notes
- Keep secrets out of the repo; use local `.env` or Xcode/Gradle user-specific config.
- When adding modules/packages, update Gradle `settings.gradle.kts` or Swift package manifests accordingly.
- Align module/file names with feature or domain (e.g., `app-ui`, `crypto-auth-core`).
