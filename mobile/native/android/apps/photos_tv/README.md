# Photos TV for Android

Native Android TV receiver for Ente Photos.

To know more about Ente, see [our main README](../../../../../README.md) or visit [ente.com](https://ente.com).

## Building from source

1. Install [Android Studio](https://developer.android.com/studio), [Rust](https://www.rust-lang.org/tools/install), and CMake (e.g. `brew install cmake`).

2. Generate the Kotlin bindings:

   ```sh
   cd rust
   cargo codegen native
   ```

3. Build the debug APK:

   ```sh
   cd mobile/native/android/apps/photos_tv
   ./gradlew :app:assembleDebug
   ```

   Optional build-time origins:

   ```sh
   PHOTOS_TV_API_ORIGIN=https://api.example.com \
   PHOTOS_TV_CAST_WORKER_ORIGIN=https://cast.example.com \
   ./gradlew :app:assembleDebug
   ```

That's it. Apart from `cargo codegen`, this is a normal Android project. Gradle cross-compiles the Rust libraries to JNI `.so` files automatically when building the app.

> [!NOTE]
>
> Re-run `cargo codegen native` whenever the UniFFI-exported surface under `rust/bindings/uniffi/` changes. Internal Rust changes are picked up by the normal Gradle build.

## Set as Android TV screensaver with adb

Install app, then run:

```sh
adb shell settings put secure screensaver_enabled 1
adb shell settings put secure screensaver_components io.ente.photos_tv/io.ente.photos_tv.PhotosTvDreamService
adb shell settings put secure screensaver_default_component io.ente.photos_tv/io.ente.photos_tv.PhotosTvDreamService
adb shell settings put secure screensaver_activate_on_sleep 1
adb shell settings put secure screensaver_activate_on_dock 1
```
