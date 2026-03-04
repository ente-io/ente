# CoreUniFFI Pod

This local CocoaPod wraps `rust/uniffi/core` for Swift usage in the Photos iOS app.

## How it works
- `Podfile` includes: `pod 'CoreUniFFI', :path => './CoreUniFFI'`.
- During `pod install`, `CoreUniFFI.podspec` runs `prepare_command`.
- The prepare step:
  - generates Swift bindings (`core.swift`) from UniFFI,
  - builds an iOS + iOS simulator XCFramework,
  - copies generated outputs into `CoreUniFFI/Sources` and `CoreUniFFI/Binaries`.

## Source control
Generated files are intentionally excluded from git:
- `Sources/core.swift`
- `Binaries/CoreUniFFIFFI.xcframework/`

Only pod wrapper metadata and scripts are tracked.

## Manual regen (optional)
From `mobile/apps/photos/ios`:
- `./scripts/generate_core_uniffi_swift.sh`
- `./scripts/build_core_uniffi_xcframework.sh`

## Prerequisites
- macOS with Xcode command line tools (`xcodebuild`).
- Rust toolchain (`cargo` + `rustup`).
- UniFFI CLI (`uniffi-bindgen`): `cargo install uniffi_bindgen_cli`.
- Rust Apple targets:
  - `rustup target add aarch64-apple-ios`
  - `rustup target add aarch64-apple-ios-sim`
  - `rustup target add x86_64-apple-ios`
