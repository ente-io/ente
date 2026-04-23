# Ensu for Android

Source code for the Ensu Android app.

To know more about Ente, see [our main README](../../../../../README.md) or visit [ente.com](https://ente.com).

## Building from source

1. Install [Android Studio](https://developer.android.com/studio), [Rust](https://www.rust-lang.org/tools/install), and CMake (e.g. `brew install cmake`).

2. Generate the Kotlin bindings:

    ```sh
    cd rust
    cargo codegen ensu-android
    ```

3. Open the project in Android Studio and run the `app-ui` module. If the Android NDK is missing, Android Studio will prompt to install it.

That's it. Apart from the `cargo codegen`, this is a normal Android project.

> [!NOTE]
>
> Re-run `cargo codegen ensu-android` whenever the UniFFI interface under `rust/uniffi` changes.
>
> Gradle cross-compiles the Rust libraries to JNI `.so` files automatically when building the app.

A custom endpoint can be baked into the build via `./gradlew :app-ui:installDebug -PENTE_API_ENDPOINT=http://localhost:8080`, or by exporting `ENTE_API_ENDPOINT` before running Gradle.

## Terminal builds

> [!NOTE]
>
> If you'd rather not open Android Studio, this section is for you.
>
> To skip the Android Studio install entirely, see [photos/docs/android-cli.md](../../../../apps/photos/docs/android-cli.md).

Build and install a debug APK on a connected device or emulator:

```sh
cd mobile/native/android/apps/ensu
./gradlew :app-ui:installDebug
adb shell am start -n io.ente.ensu/.MainActivity
```

Release APK:

```sh
./gradlew :app-ui:assembleRelease
```

Output: `app-ui/build/outputs/apk/release/app-ui-release.apk`.

Release AAB (Play Store bundle):

```sh
./gradlew :app-ui:bundleRelease
```

Output: `app-ui/build/outputs/bundle/release/app-ui-release.aab`.

Release builds use a debug keystore located at `debug.keystore`. For production releases, configure your own signing keys in `app-ui/build.gradle.kts`.

## Modules

- `app-ui/` — Compose UI and app entry point.
- `domain/` — Business logic and state (pure Kotlin).
- `data/` — Repositories, network, storage.
- `crypto-auth-core/` — Cryptographic primitives (UniFFI-wrapped Rust).

The Rust glue for `db` / `sync` / `inference` lives outside this app, at [`mobile/native/android/packages/rust/`](../../packages/rust/).
