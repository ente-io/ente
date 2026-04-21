# Ensu Android

## Prerequisites

- Android Studio or command-line tools
- JDK 17
- Android SDK with API level 35 (install in a default location or set `ANDROID_HOME`/`ANDROID_SDK_ROOT`)
- Android NDK (install via `sdkmanager "ndk;<version>"`; optionally set `NDK_VERSION` to select a specific version)
- Rust toolchain

## Building

### 1. Generate Kotlin bindings

Before building the Android app, generate the UniFFI Kotlin bindings:

```bash
cd rust
cargo codegen ensu-android
```

This refreshes the generated Kotlin sources in:
- `android/apps/ensu/crypto-auth-core/src/main/java/io/ente/ensu/crypto/core.kt`
- `android/packages/rust/src/main/kotlin/io/ente/labs/ensu_db/db.kt`
- `android/packages/rust/src/main/kotlin/io/ente/labs/ensu_sync/sync.kt`
- `android/packages/rust/src/main/kotlin/io/ente/labs/inference_rs/inference.kt`

### 2. Build Debug APK

```bash
cd mobile/native/android/apps/ensu
./gradlew :app-ui:assembleDebug
```

Gradle builds the Rust JNI libraries automatically for the relevant ABI.

Output: `app-ui/build/outputs/apk/debug/app-ui-debug.apk`

### 3. Build Release APK

```bash
./gradlew :app-ui:assembleRelease
```

Release builds include the full shipped ABI set.

Output: `app-ui/build/outputs/apk/release/app-ui-release.apk`

### 4. Build Release AAB

```bash
./gradlew :app-ui:bundleRelease
```

Output: `app-ui/build/outputs/bundle/release/app-ui-release.aab`

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

Launch the app:

```bash
adb shell am start -n io.ente.ensu/.MainActivity
```

### Install Release Build

```bash
adb install -r app-ui/build/outputs/apk/release/app-ui-release.apk
```

To target a specific device, prefix the `adb` commands with `-s <serial>`.

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
