# Repository Guidelines

## Project Structure & Module Organization
`lib/` houses the Flutter client (`core/`, `services/`, `ui/`, `db/`). Tests live in `test/` (unit & widget) and `integration_test/`. Platform shells are `android/` and `ios/`; Rust crates and bridge helpers sit in `rust/` and `rust_builder/`. Assets, fonts, and localization configs are in `assets/`, `fonts/`, `l10n.yaml`, with generated code in `lib/generated/`. Automation scripts include `scripts/`, `run.sh`, `build-apk.sh`, and release tooling under `fastlane/`.

## Build, Test & Development Commands
Run `flutter pub get` after dependency edits. Launch the dev flavor via `./run.sh` (reads `.env`) or use `flutter run -t lib/main.dart --flavor independent`. Regenerate Rust bindings with `flutter_rust_bridge_codegen generate` before builds. Android releases rely on `flutter build apk --release --flavor independent`; for iOS run `cd ios && pod install` then `flutter build ios`. Use `./build-apk.sh` when Gradle artifacts from `thirdparty/transistor-background-fetch` need refreshing.

## Coding Style & Naming Conventions
Use 2-space indentation and format with `dart format .` (trailing commas preserved). `analysis_options.yaml` enforces rules such as `prefer_const_constructors`, `require_trailing_commas`, and `always_use_package_imports`. Keep files `snake_case.dart`, classes `PascalCase`, private members `_camelCase`. Avoid `print`; rely on the log utilities under `lib/core/`.

## Testing Guidelines
Mirror source names with `*_test.dart`. Run only suites that cover your changes—`flutter test` (or a filtered target) when relevant tests exist, and skip it if no tests touch your work. Device flows stay in `integration_test/` (`flutter test integration_test`). Rust-facing updates should extend coverage with `cargo test` plus Dart adapter checks. Document new fixtures or goldens in `docs/`.

## Commit & Pull Request Guidelines
Commits should stay concise and imperative, summarising all substantial code changes; there is no enforced prefix, so mirror existing author patterns. PR titles must tag the scope: `[mob][photos] …` for this app, `[mob][auth]`, `[mob][locker]`, `[mob][packages]`, `[web]`, `[desktop]`, `[server]`, `[infra]`, or package-specific tags like `[mob][native_video_editor]`. Use `.github/pull_request_template.md` as your outline. Populate the Tests section with Markdown checkboxes covering only the validations needed pre-merge (keep it tight, relevant, and ≤5 items); omit the entire section when nothing needs to run. Add QA notes and UI captures when applicable, and verify `flutter analyze .` plus only the applicable tests from above before submitting.

## Rust & Localization Notes
Regenerate Dart bindings when Rust APIs change and keep generated code in `lib/src/rust/`. Exercise Rust crates with `cargo test` during such updates. For copy edits, update `lib/l10n/intl_en.arb` then run `flutter gen-l10n` (configured by `l10n.yaml`) to refresh `lib/generated/`, and coordinate Crowdin syncs through `crowdin.yml`.
