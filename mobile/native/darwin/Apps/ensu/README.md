# Ensu Apple Platforms

## Build (Terminal)

All commands below assume you run them from `darwin/Apps/ensu`.

### Debug Build (Simulator)
```bash
cd darwin/Apps/ensu
xcodebuild \
  -project ensu.xcodeproj \
  -scheme Ensu \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -derivedDataPath build
```

### Debug Build (Device)
```bash
cd darwin/Apps/ensu
xcodebuild \
  -project ensu.xcodeproj \
  -scheme Ensu \
  -configuration Debug \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath build
```

### Release Build (Archive)
```bash
cd darwin/Apps/ensu
xcodebuild \
  -project ensu.xcodeproj \
  -scheme Ensu \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -archivePath build/Ensu.xcarchive \
  archive
```

To export an IPA, provide an `ExportOptions.plist` and run:
```bash
xcodebuild \
  -exportArchive \
  -archivePath build/Ensu.xcarchive \
  -exportPath build/Export \
  -exportOptionsPlist /path/to/ExportOptions.plist
```

## Installation (Terminal)

### Debug (Simulator)
```bash
cd darwin/Apps/ensu
xcrun simctl boot "iPhone 15" || true
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Ensu.app
xcrun simctl launch booted io.ente.ensu
```

### Debug (Physical Device)
```bash
cd darwin/Apps/ensu
xcrun devicectl device list
xcrun devicectl device install app \
  --device <DEVICE_UDID> \
  build/Build/Products/Debug-iphoneos/Ensu.app
```

### Release (IPA)
Install the exported IPA via Apple Configurator or TestFlight after `xcodebuild -exportArchive`.

## Custom API Endpoint

Set the endpoint at build time using `ENTE_API_ENDPOINT`. If it is not set, the app defaults to `https://api.ente.io`.

```bash
cd darwin/Apps/ensu
ENTE_API_ENDPOINT="https://your-endpoint.example" \
  xcodebuild \
  -project ensu.xcodeproj \
  -scheme Ensu \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -derivedDataPath build
```


