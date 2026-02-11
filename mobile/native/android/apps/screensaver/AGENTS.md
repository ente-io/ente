# Repository Guidelines

## Project Structure & Module Organization
- `app/` is the only module and contains the Android application.
- Source code lives under `app/src/main/java/io/ente/screensaver/` (feature folders like `dream`, `photos`, `slideshow`).
- Android resources are in `app/src/main/res/`.
- Debug-only assets and config live in `app/src/debug/` (see `app/src/debug/assets/sample_photos/`).
- Build outputs are generated in `app/build/` (do not commit).

## Build, Test, and Development Commands
- `./gradlew assembleDebug` builds a debug APK for local testing.
- `./gradlew installDebug` installs the debug build on a connected device/emulator.
- `./gradlew assembleRelease` builds a release APK (uses debug signing per `app/build.gradle.kts`).
- `./gradlew lint` runs Android lint checks.
- `./gradlew clean` removes build outputs.

## Coding Style & Naming Conventions
- Language: Kotlin (JVM 17). Follow standard Kotlin/Android style.
- Indentation: 4 spaces; braces and line breaks should match Android Studio defaults.
- Naming: classes in `UpperCamelCase`, functions/variables in `lowerCamelCase`, constants in `UPPER_SNAKE_CASE`.
- Keep changes focused and avoid large refactors unless required.

## Testing Guidelines
- No test suites are currently checked in.
- If adding tests, place unit tests under `app/src/test/java/` and instrumentation tests under `app/src/androidTest/java/`.
- Name test files with `*Test.kt` and keep test names descriptive.

## Commit & Pull Request Guidelines
- This repository has no commit history yet; use short, imperative commit subjects (e.g., "Add slideshow timer").
- PRs should describe the change, include testing notes (commands run), and add screenshots if UI changes are involved.

## Configuration Tips
- Ensure `local.properties` points to a valid Android SDK on your machine.
