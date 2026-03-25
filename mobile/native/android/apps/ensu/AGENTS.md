# Ente Android Ensu App Agent Guidelines

This file provides guidance for AI coding agents working on the Ente Android Ensu application.

## Project Overview

Ente is a monorepo containing multiple interconnected components. The Ensu Android app provides native Android experiences with Kotlin and Gradle, focusing on performance and platform integration.

## Project Structure & Module Organization
- `app-ui/`: Android UI layer (Compose screens, resources under `src/main/res`).
- `domain/`: Business logic and use cases.
- `data/`: Repositories, data sources, and persistence/networking.
- `crypto-auth-core/`: Shared crypto/auth logic.
- `rust/` (via `android/packages/rust`): Rust integration module.
- Gradle configuration lives in `build.gradle.kts`, `settings.gradle.kts`, and `gradle/`.

## Build, Lint & Test Commands

### Android (Kotlin/Gradle)

```bash
# Build debug APK
./gradlew assembleDebug

# Install debug build
./gradlew :app-ui:installDebug

# Run unit tests
./gradlew test

# Run Android lint
./gradlew lint

# Run specific test
./gradlew :module:test --tests "*TestName*"
```

### Custom API Endpoint
Override the default API (`https://api.ente.io`) with `ENTE_API_ENDPOINT`:

```bash
ENTE_API_ENDPOINT=https://your-endpoint ./gradlew :app-ui:installDebug
```

Or via Gradle property:

```bash
./gradlew :app-ui:installDebug -PENTE_API_ENDPOINT=https://your-endpoint
```

## Code Style Guidelines

### Kotlin (Android)
- **Formatting**: 4-space indentation, standard Kotlin conventions
- **Naming**: camelCase for variables/functions, PascalCase for classes/types
- **Imports**: Organize with proper grouping
- **Error Handling**: Use proper exception handling patterns
- **Architecture**: Follow MVVM/clean architecture patterns
- Keep file/module names aligned with feature or domain (e.g., `app-ui`, `crypto-auth-core`)
- Prefer small, focused classes and functions; avoid mixing UI and domain logic

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
- Use JUnit for JVM unit tests under `src/test` in each module
- Name tests after behavior (e.g., `TokenRefreshTest`, `AuthStateReducerTest`)
- Run tests with `./gradlew test` and keep new logic covered where feasible

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
- Do not commit secrets. Use local Gradle properties or environment variables.
- Store device-specific configs outside the repo when possible.
- When adding modules/packages, update Gradle configuration files accordingly.
