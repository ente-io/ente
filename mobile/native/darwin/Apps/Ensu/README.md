# Ensu for iOS

Source code for the Ensu iOS app.

To know more about Ente, see [our main README](../../../../../README.md) or visit [ente.com](https://ente.com).

## Building from source

1. Install [Xcode](https://developer.apple.com/xcode/), [Rust](https://www.rust-lang.org/tools/install), and CMake (e.g. `brew install cmake`).

2. Generate the Swift bindings:

    ```sh
    cd rust
    cargo codegen ensu-ios
    ```

3. Open `Ensu.xcodeproj` in Xcode and run the `Ensu` scheme.

That's it. Apart from the `cargo codegen`, this is a normal iOS project.

> [!NOTE]
>
> Re-run `cargo codegen ensu-ios` whenever the UniFFI interface under `rust/uniffi` changes.
>
> Xcode compiles and statically links the Rust libraries automatically when building the app.

A custom endpoint can be baked into the build via `xcodebuild ENTE_API_ENDPOINT=http://localhost:8080 ...` or by editing the user-defined `ENTE_API_ENDPOINT` build setting in the `Ensu` target.

## Terminal builds

> [!NOTE]
>
> If you'd rather not open Xcode, this section is for you.

Build and run on the simulator:

```sh
open -a Simulator

cd mobile/native/darwin/Apps/Ensu
xcodebuild -scheme Ensu -destination 'platform=iOS Simulator,name=iPhone 17'

xcrun simctl install booted \
  ~/Library/Developer/Xcode/DerivedData/Ensu-*/Build/Products/Debug-iphonesimulator/Ensu.app
xcrun simctl launch booted io.ente.ensu
```

Create a release archive:

```sh
xcodebuild archive -scheme Ensu \
  -destination 'generic/platform=iOS' \
  -archivePath build/Ensu.xcarchive
```

Export an IPA from the archive:

```sh
xcodebuild -exportArchive \
  -archivePath build/Ensu.xcarchive \
  -exportPath build/Export \
  -exportOptionsPlist scripts/ExportOptions-AppStore.plist
```

### Tests

Run the app-hosted inference integration test with these environment variables:

```sh
TEST_RUNNER_ENSU_TEST_MODEL=/path/to/model.gguf \
TEST_RUNNER_ENSU_TEST_MMPROJ=/path/to/mmproj.gguf \
TEST_RUNNER_ENSU_TEST_IMAGE=/path/to/image.png \
xcodebuild test -scheme Ensu \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```
