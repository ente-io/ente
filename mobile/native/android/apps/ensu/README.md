# Ensu Android

## Prerequisites

- Android Studio or command-line tools
- JDK 17
- Android SDK with API level 35 (install in a default location or set `ANDROID_HOME`/`ANDROID_SDK_ROOT`)
- Android NDK (install via `sdkmanager "ndk;<version>"`; optionally set `NDK_VERSION` to select a specific version)
- Rust toolchain and `cargo-ndk` (`cargo install cargo-ndk`)
- Python 3 (used to patch llama.cpp mtmd sources)

## Building

### 1. Build Rust Libraries

Before building the Android app, compile the Rust native libraries. Ensure the SDK is installed in a default location or set `ANDROID_HOME`/`ANDROID_SDK_ROOT` to the SDK containing an NDK. Optionally set `NDK_VERSION` to select a specific version. The build script applies the llama.cpp mtmd patch; set `APPLY_LLAMA_MTMD_PATCH=0` to skip it.

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

## Custom API Endpoint

Set `ENTE_API_ENDPOINT` to override the default (`https://api.ente.io`).

```bash
ENTE_API_ENDPOINT=https://your-endpoint ./gradlew :app-ui:installDebug
```

Or via Gradle property:

```bash
./gradlew :app-ui:installDebug -PENTE_API_ENDPOINT=https://your-endpoint
```

## Project Structure

- `app-ui/` - Main application module (Compose UI)
- `domain/` - Domain layer (business logic, state management)
- `data/` - Data layer (repositories, network, storage)
- `crypto-auth-core/` - Cryptographic authentication utilities
