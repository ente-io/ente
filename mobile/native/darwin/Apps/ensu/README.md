# Ensu Apple Platforms

## Build

Open the Xcode project:

```bash
open darwin/Apps/ensu/ensu.xcodeproj
```

## Custom API Endpoint

Set the `ENTE_API_ENDPOINT` value in the app’s Info.plist (or via an Xcode build setting) to override the default `https://api.ente.io`.

**Option A: Info.plist**
- Add a new key `ENTE_API_ENDPOINT` with your endpoint URL as the value.

**Option B: Build Setting**
- In Xcode, add a User-Defined Setting `ENTE_API_ENDPOINT` and reference it in Info.plist as `$(ENTE_API_ENDPOINT)`.

If the key is missing or empty, the app defaults to `https://api.ente.io`.
