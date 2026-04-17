# Ensu Apple Platforms

## Build (Terminal)

All commands below assume you run them from `darwin/Apps/Ensu`.

## Quick scripts

```bash
./setup-mac.sh             # Check prerequisites and resolve packages
./build.sh                 # Debug build for iOS simulator (prefers booted iPhone)
./build.sh device          # Debug build for connected iOS device
./build.sh archive         # Release archive (.xcarchive)
./build.sh ipa             # Release IPA export (uses ExportOptions-AppStore.plist)
./run.sh                   # Build + install + launch on iOS simulator (prefers booted iPhone)
```

Helpful flags:

- `--destination-id <id>` to force a specific simulator/device
- `--endpoint <url>` to set `ENTE_API_ENDPOINT`
- `--archive-path`, `--export-path`, `--export-options-plist` for release flows
- `--skip-build` for `run.sh`

Run `./build.sh --help` or `./run.sh --help` for full options.

## Generated bindings & dependencies

- SwiftMath is fetched via SwiftPM (`https://github.com/mgriebling/SwiftMath.git`).
- UniFFI Swift bindings are generated locally and gitignored:
  - `Ensu/Generated/core*`, `Ensu/Generated/db*`, `Ensu/Generated/sync*`, `Ensu/Generated/inference*`

The Xcode build script (`scripts/build-rust.sh`) builds the Rust static libs directly into
`$(TARGET_TEMP_DIR)/ensu_rust` and regenerates the `core`, `db`, `sync`, and `inference`
Swift bindings into `Ensu/Generated/` as part of the build.

### Debug Build (Simulator)
```bash
cd darwin/Apps/Ensu
xcodebuild \
  -project Ensu.xcodeproj \
  -scheme Ensu \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -derivedDataPath build
```

## Tests

Run the app-hosted inference integration test from Terminal with `TEST_RUNNER_...` environment
variables so they reach the XCTest runner process:

```bash
cd darwin/Apps/Ensu
TEST_RUNNER_ENSU_TEST_MODEL=/path/to/model.gguf \
TEST_RUNNER_ENSU_TEST_MMPROJ=/path/to/mmproj.gguf \
TEST_RUNNER_ENSU_TEST_IMAGE=/path/to/image.png \
xcodebuild test \
  -project Ensu.xcodeproj \
  -scheme Ensu \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  SWIFT_ENABLE_EXPLICIT_MODULES=NO
```

### Debug Build (Device)
```bash
cd darwin/Apps/Ensu
xcodebuild \
  -project Ensu.xcodeproj \
  -scheme Ensu \
  -configuration Debug \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build
```

### Release Build (Archive)
```bash
cd darwin/Apps/Ensu
xcodebuild \
  -project Ensu.xcodeproj \
  -scheme Ensu \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath build/Archive/Ensu.xcarchive \
  archive
```

### Release IPA (App Store)
```bash
cd darwin/Apps/Ensu
xcodebuild \
  -exportArchive \
  -archivePath build/Archive/Ensu.xcarchive \
  -exportPath build/Export \
  -exportOptionsPlist ExportOptions-AppStore.plist
```

## Installation (Terminal)

### Debug (Simulator)
```bash
cd darwin/Apps/Ensu
xcrun simctl boot "iPhone 15" || true
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Ensu.app
xcrun simctl launch booted io.ente.ensu
```

### Debug (Physical Device)
```bash
cd darwin/Apps/Ensu
xcrun devicectl device list
xcrun devicectl device install app \
  --device <DEVICE_UDID> \
  build/Build/Products/Debug-iphoneos/Ensu.app
```

### Release (IPA)
Install the exported IPA via Apple Configurator or TestFlight after `xcodebuild -exportArchive`.

Note: App Store IPA export requires valid distribution signing certificate/profile on this machine.

## Custom API Endpoint

Set the endpoint at build time using `ENTE_API_ENDPOINT`. If it is not set, the app defaults to `https://api.ente.io`.

```bash
cd darwin/Apps/Ensu
ENTE_API_ENDPOINT="https://your-endpoint.example" \
  xcodebuild \
  -project Ensu.xcodeproj \
  -scheme Ensu \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -derivedDataPath build
```
