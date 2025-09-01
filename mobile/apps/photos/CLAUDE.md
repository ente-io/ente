# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Ente Photos Mobile App

This is the Flutter application for Ente Photos - an end-to-end encrypted photo storage service. This is Ente's flagship mobile app where the project started.

## Development Setup

### Prerequisites
- Flutter v3.32.8
- Rust (for Flutter Rust Bridge)
- Xcode (for iOS development)
- Android Studio (for Android development)

### Initial Setup
```bash
# Install Flutter Rust Bridge
cargo install flutter_rust_bridge_codegen
flutter_rust_bridge_codegen generate

# Update git submodules
git submodule update --init --recursive

# Enable git hooks
git config core.hooksPath hooks

# Get dependencies
flutter pub get
```

### iOS Setup
```bash
cd ios
pod install
cd ..
```

## Common Commands

### Running the App

#### Development Mode
```bash
# Android with independent flavor (most common for dev)
flutter run -t lib/main.dart --flavor independent

# Using the run script with environment variables
./run.sh  # Uses .env file for configuration
```

#### Build Commands
```bash
# Android APK (release)
flutter build apk --release --flavor independent

# iOS build
flutter build ios

# Clean build artifacts
flutter clean
```

### Code Quality
```bash
# Run static analysis
flutter analyze .

# Run tests
flutter test

# Format code
dart format .

# Check formatting without changes
dart format --set-exit-if-changed .
```

### Using Melos (from mobile/ directory)
```bash
# Run photos app
melos run:photos:apk

# Build photos APK
melos build:photos:apk

# Clean photos project
melos clean:photos
```

## Architecture Overview

### Core Components

**lib/main.dart** - Entry point, initializes app configuration and services

**lib/app.dart** - Main app widget with theme and routing setup

### Key Services

**lib/core/configuration.dart** - Manages app settings, user preferences, and encryption keys

**lib/services/**
- `sync_service.dart` - Handles photo synchronization between device and server
- `collections_service.dart` - Manages albums/folders
- `file_magic_service.dart` - Handles file metadata encryption
- `machine_learning/` - ML features (face recognition, semantic search)

### Data Layer

**lib/db/** - SQLite databases for local caching
- `files_db.dart` - File metadata storage
- `collections_db.dart` - Album/folder data
- `ml/` - ML-related data storage

**lib/models/** - Data models for files, collections, user data

### UI Structure

**lib/ui/**
- `home/` - Main gallery and home screen components
- `viewer/` - Photo/video viewing and editing
- `collections/` - Album and folder management
- `settings/` - App settings and preferences
- `account/` - Authentication and account management

### Encryption & Security

All file data and metadata is encrypted client-side using:
- Master key (never leaves device unencrypted)
- Collection keys (per album/folder)
- File keys (unique per file)

Key files:
- `lib/utils/crypto_util.dart` - Encryption/decryption utilities
- `lib/core/constants.dart` - Crypto constants

### State Management

Uses a combination of:
- `ChangeNotifier` for simple state
- Event bus (`lib/core/event_bus.dart`) for app-wide events
- Inherited widgets for dependency injection

### Platform Integration

**android/** - Android-specific code and configurations
- Multiple flavors: `independent`, `playstore`, `fdroid`

**ios/** - iOS-specific code and configurations

## Important Notes

### Security Considerations
- All encryption happens client-side
- Server never has access to unencrypted data or keys
- Password-derived key encryption for master key
- Public/private key pairs for sharing

### Build Flavors
- `independent` - Self-updating APK from GitHub
- `playstore` - Google Play Store version
- `fdroid` - F-Droid version without proprietary dependencies

### Dependencies
The app uses several custom forks of packages (see pubspec.yaml):
- Custom Chewie fork for video player
- Battery info fork for device stats
- Computer fork for isolate computations

### Testing on Device
For Android development, the `independent` flavor is recommended as it includes self-update functionality and doesn't require Play Services.
