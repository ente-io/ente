# Repository Guidelines

## Project Structure & Module Organization
- `android/apps/ensu`: Android app workspace (Gradle Kotlin DSL). Key modules include `app-ui`, `domain`, `data`, `crypto-auth-core`, and `rust`.
- `android/packages/rust`: Shared Rust/Android integration module referenced by the app workspace.
- `darwin/Apps/ensu` and `darwin/Apps/tv`: Xcode projects for Apple platforms.
- `darwin/Packages/*`: Swift Package Manager libraries. Source code under `Sources/`, tests under `Tests/`.

## Build, Test, and Development Commands
Run commands from the module root noted below.
- Android build (debug): `cd android/apps/ensu && ./gradlew assembleDebug`
- Android unit tests: `cd android/apps/ensu && ./gradlew test`
- Apple apps (open in Xcode):
  - `open darwin/Apps/ensu/ensu.xcodeproj`
  - `open darwin/darwin.xcworkspace`
- Swift package tests: `swift test --package-path darwin/Packages/EnteCore`

## Coding Style & Naming Conventions
- Kotlin: 4-space indentation, `camelCase` for variables/functions, `PascalCase` for types.
- Swift: 4-space indentation, `camelCase` for members, `PascalCase` for types.
- Align module/file names with feature or domain (e.g., `app-ui`, `crypto-auth-core`).

## Testing Guidelines
- Swift packages use `XCTest`; place tests in `darwin/Packages/*/Tests`.
- Name tests by behavior (e.g., `TokenRefreshTests`, `RefreshTokenSucceedsWhenExpired`).
- Prefer focused unit tests per module; add integration tests in app targets as needed.

## Commit & Pull Request Guidelines
- Commit messages: short, imperative subjects, often with tags like `[mob]`, `[web]`, or `fix(scope):`.
- PRs should include a clear description and reasoning, linked issues, and screenshots for UI changes (Android/iOS/macOS/tvOS).

## Configuration & Security Notes
- Keep secrets out of the repo; use local `.env` or Xcode/Gradle user-specific config.
- When adding modules/packages, update Gradle `settings.gradle.kts` or Swift package manifests accordingly.
