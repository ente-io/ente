# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Prerequisites
- Flutter v3.32.8
- Rust (for Flutter Rust Bridge)
- Flutter Rust Bridge: `cargo install flutter_rust_bridge_codegen`

### Development
- **Run development build**: `flutter run -t lib/main.dart --flavor independent`
- **Alternative with env file**: `./run.sh` (uses .env file for configuration)
- **Generate Rust bindings**: `flutter_rust_bridge_codegen generate`

### Build Commands
- **Build APK**: `flutter build apk --release --flavor independent`
- **Build iOS**: `flutter build ios`
- **iOS setup**: `cd ios && pod install && cd ..`

### Testing
- **Run all tests**: `flutter test`
- **Run specific test**: `flutter test test/path/to/test_file.dart`
- **Integration tests**: `flutter test integration_test/`
- **Performance tests**: Use scripts in `scripts/` directory

### Code Generation
- **Generate localization**: Automatically runs with flutter (see l10n.yaml)
- **Generate launcher icons**: `dart run flutter_launcher_icons`
- **Generate splash screen**: `dart run flutter_native_splash:create`

## Architecture

### Core Services Structure
The app follows a service-oriented architecture with dependency injection via `service_locator.dart`:

- **Authentication**: `services/account/` - handles user authentication, billing, passkeys
- **Sync Services**: `services/sync/` - local and remote file synchronization
- **Machine Learning**: `services/machine_learning/` - face detection, semantic search, ML models
- **Collections**: `services/collections_service.dart` - manages photo albums and folders
- **File Management**: `services/files_service.dart`, `utils/file_uploader.dart`

### Data Layer
- **Databases**: SQLite with migrations via `sqflite_migration`
  - `db/files_db.dart` - main file storage
  - `db/collections_db.dart` - collections and albums
  - `db/ml/` - ML-related data (embeddings, face data)
- **Models**: `models/` directory contains data models with freezed for immutables

### UI Architecture
- **State Management**: Event-based architecture using `event_bus`
- **Navigation**: Standard Flutter navigation with named routes
- **Theming**: Custom theme system in `theme/` and `ente_theme_data.dart`
- **Main screens**: Located in `ui/` with feature-specific subdirectories

### Key Features Implementation
- **End-to-end encryption**: Uses `ente_crypto` plugin with libsodium
- **Photo upload**: Background upload via `workmanager` and custom uploader
- **Video playback**: Multiple players (media_kit, video_player, chewie)
- **Image editing**: `pro_image_editor` and custom video editor
- **Home widgets**: iOS and Android widgets in `ios/EnteWidget/` and via `home_widget` package

### Platform-Specific Code
- **Android**: Flavors configured in `android/app/build.gradle`
- **iOS**: Widget extensions in `ios/EnteWidget/`
- **Rust integration**: FFI bridge in `rust/` directory