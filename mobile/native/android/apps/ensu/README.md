# Ensu Android

## Prerequisites

- Android Studio or command-line tools
- JDK 17
- Android SDK with API level 34
- Rust toolchain (for building native libraries)

## Building

### 1. Build Rust Libraries

Before building the Android app, compile the Rust native libraries:

```bash
cd mobile/native/android/packages/rust/tool
./build_android.sh
```

### 2. Build Debug APK

```bash
cd mobile/native/android/apps/ensu
./gradlew :app-ui:assembleDebug
```

Output: `app-ui/build/outputs/apk/debug/app-ui-debug.apk`

### 3. Build Release APK

```bash
./gradlew :app-ui:assembleRelease
```

Output: `app-ui/build/outputs/apk/release/app-ui-release.apk`

Note: Release builds use a debug keystore located at `debug.keystore`. For production releases, configure your own signing keys in `app-ui/build.gradle.kts`.

## Installation

### Install Debug Build

```bash
./gradlew :app-ui:installDebug
```

Or via adb:

```bash
adb install -r app-ui/build/outputs/apk/debug/app-ui-debug.apk
```

### Install Release Build

```bash
adb install -r app-ui/build/outputs/apk/release/app-ui-release.apk
```

Note: If upgrading from a differently signed build, uninstall first:

```bash
adb uninstall io.ente.ensu
```

## Project Structure

- `app-ui/` - Main application module (Compose UI)
- `domain/` - Domain layer (business logic, state management)
- `data/` - Data layer (repositories, network, storage)
- `crypto-auth-core/` - Cryptographic authentication utilities
