## 0.2.0 - March 12, 2021
* migrates to ffi 1.0.0
* stable null safety

## 0.2.0-nullsafety.1 - February 5, 2021
* adds support for sodium_core_hchacha and hsalsa (merge 0.1.11)

## 0.2.0-nullsafety.0 - February 5, 2021
* implements null safety

## 0.1.11 - February 5, 2021
* adds support for loading libsodium on Linux and Windows
* adds support for sodium_core_hchacha and hsalsa

## 0.1.10 - December 11, 2020
* adds support for sodium_runtime_*, sodium_memcmp, sodium_pad and sodium_unpad

## 0.1.9 - October 31, 2020
* sets Android build.gradle minSdkVersion 16, fixing implicit permissions READ_PHONE_STATE, READ_EXTERNAL_STORAGE and WRITE_EXTERNAL_STORAGE

## 0.1.8 - October 2, 2020
* backwards incompatible Sodium.cryptoPwhashStr* changes, str return value and parameter type changed from ascii decoded String to null terminated Uint8List

## 0.1.7 - September 30, 2020
* improves API documentation
* removes obsolete convert package dependency
* fixes Android deprecated API build warning

## 0.1.6 - September 30, 2020
* fixes "cannot find symbol" compile error on Android

## 0.1.5 - September 30, 2020
* fixes symbol lookup issue since flutter 1.20
* fixes platforms key in pubspec.yaml

## 0.1.4 - September 16, 2020
* adds sodium hex and base64 conversion helpers
* removes sodium prefix from version and init functions (breaks API)
* fixes generic_hash crash on Android

## 0.1.3 - July 17, 2020
* reverts invalid multi-platform pubspec settings

## 0.1.2 - July 16, 2020
* fixes documentation and multi-platform support warnings

## 0.1.1 - July 15, 2020
* fixes "Failed to lookup symbol" errors on iOS in release mode.

## 0.1.0 - June 10, 2020
* rewrite flutter_sodium using FFI

