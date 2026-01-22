# Repository Guidelines

## Project Structure & Module Organization
- `app-ui/`: Android UI layer (Compose screens, resources under `src/main/res`).
- `domain/`: Business logic and use cases.
- `data/`: Repositories, data sources, and persistence/networking.
- `crypto-auth-core/`: Shared crypto/auth logic.
- `rust/` (via `android/packages/rust`): Rust integration module.
- Gradle configuration lives in `build.gradle.kts`, `settings.gradle.kts`, and `gradle/`.

## Build, Test, and Development Commands
Run commands from `android/apps/ensu`.
- `./gradlew assembleDebug`: Build a debug APK.
- `./gradlew test`: Run unit tests for modules that include tests.
- `./gradlew lint`: Run Android lint checks (if configured).

## Coding Style & Naming Conventions
- Kotlin: 4-space indentation, `camelCase` for functions/variables, `PascalCase` for classes/types.
- Keep file/module names aligned with feature or domain (e.g., `app-ui`, `crypto-auth-core`).
- Prefer small, focused classes and functions; avoid mixing UI and domain logic.

## Testing Guidelines
- Use JUnit for JVM unit tests under `src/test` in each module.
- Name tests after behavior (e.g., `TokenRefreshTest`, `AuthStateReducerTest`).
- Run tests with `./gradlew test` and keep new logic covered where feasible.

## Commit & Pull Request Guidelines
- Commit messages are short, imperative, and often tagged (e.g., `[mob] Fix login crash`).
- PRs should include a clear summary, reasoning, and linked issues.
- Attach screenshots for UI changes on Android.

## Security & Configuration Tips
- Do not commit secrets. Use local Gradle properties or environment variables.
- Store device-specific configs outside the repo when possible.
