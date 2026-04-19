# Ensu for iOS

Source code for the Ensu iOS app.

To know more about Ente, see [our main README](../../../../../README.md) or
visit [ente.com](https://ente.com).

## Building from source

1. Install [Xcode](https://developer.apple.com/xcode/),
[Rust](https://www.rust-lang.org/tools/install), and CMake (e.g.
`brew install cmake`).

2. Generate the Rust bindings:

    ```sh
    cd rust
    cargo codegen ensu-ios
    ```

3. Open `Ensu.xcodeproj` in Xcode and run the `Ensu` scheme.

That's it. From here on it's a normal iOS project.

> [!NOTE]
>
> Re-run `cargo codegen ensu-ios` whenever the UniFFI interface under `rust/uniffi` changes.

#### Custom API endpoint

To connect to a custom endpoint, define
`ENTE_API_ENDPOINT` either via `xcodebuild ENTE_API_ENDPOINT=http://localhost:8080 ...` or by editing the user-defined `ENTE_API_ENDPOINT` build setting in the
`Ensu` target.

## Terminal builds

If you want to build from the terminal instead of Xcode,

```sh
xcodebuild \
  -scheme Ensu \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  SWIFT_ENABLE_EXPLICIT_MODULES=NO
```

Release archive:

```sh
xcodebuild \
  -scheme Ensu \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath build/Archive/Ensu.xcarchive \
  archive \
  SWIFT_ENABLE_EXPLICIT_MODULES=NO
```

Export an IPA from the archive:

```sh
xcodebuild \
  -exportArchive \
  -archivePath build/Archive/Ensu.xcarchive \
  -exportPath build/Export \
  -exportOptionsPlist ExportOptions-AppStore.plist
```

### Tests

Run the app-hosted inference integration test with these environment variables:

```sh
TEST_RUNNER_ENSU_TEST_MODEL=/path/to/model.gguf \
TEST_RUNNER_ENSU_TEST_MMPROJ=/path/to/mmproj.gguf \
TEST_RUNNER_ENSU_TEST_IMAGE=/path/to/image.png \
xcodebuild test \
  -scheme Ensu \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  SWIFT_ENABLE_EXPLICIT_MODULES=NO
```
