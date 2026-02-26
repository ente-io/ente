# EnteRustCryptoFFI Artifacts

`EnteRustCryptoFFI.xcframework` is generated locally and is intentionally not checked into git.

Regenerate it from repo root with:

```bash
mobile/native/darwin/Packages/EnteCrypto/rust/tvos-crypto-ffi/build-xcframework.sh
```

The Swift package at `mobile/native/darwin/Packages/EnteCrypto/Package.swift` expects the generated output at:

`mobile/native/darwin/Packages/EnteCrypto/Binaries/EnteRustCryptoFFI.xcframework`
