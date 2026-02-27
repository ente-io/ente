#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT/../../../.." && pwd)"
RUST_DIR="$REPO_ROOT/rust/uniffi/core"
SWIFT_OUT_DIR="$ROOT/Runner/Generated/CoreUniFFI"
XCFRAMEWORK_OUT="$ROOT/Runner/Generated/CoreUniFFIFFI.xcframework"
LIB_NAME="libcore.a"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script must run on macOS to build Apple XCFrameworks." >&2
  exit 1
fi

if ! command -v cargo >/dev/null 2>&1; then
  echo "cargo not found. Install Rust toolchain (https://rustup.rs)." >&2
  exit 1
fi

if ! command -v rustup >/dev/null 2>&1; then
  echo "rustup not found. Install Rust toolchain (https://rustup.rs)." >&2
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found. Install Xcode and command line tools." >&2
  exit 1
fi

ensure_rust_target() {
  local target="$1"
  if ! rustup target list --installed | grep -qx "$target"; then
    echo "Missing Rust target '$target'. Install with: rustup target add $target" >&2
    exit 1
  fi
}

ensure_rust_target "aarch64-apple-ios"
ensure_rust_target "aarch64-apple-ios-sim"
ensure_rust_target "x86_64-apple-ios"

"$ROOT/scripts/generate_core_uniffi_swift.sh"

HEADER_DIR="$ROOT/build/core_uniffi_headers"
HEADER_SRC="$SWIFT_OUT_DIR/coreFFI.h"
MODULEMAP_SRC="$SWIFT_OUT_DIR/coreFFI.modulemap"

rm -rf "$HEADER_DIR" "$ROOT/build/core_uniffi"
mkdir -p "$HEADER_DIR" "$ROOT/build/core_uniffi/ios" "$ROOT/build/core_uniffi/ios-sim"

if [[ ! -f "$HEADER_SRC" ]] || [[ ! -f "$MODULEMAP_SRC" ]]; then
  echo "Expected UniFFI headers in $SWIFT_OUT_DIR" >&2
  exit 1
fi

cp "$HEADER_SRC" "$HEADER_DIR/"
cp "$MODULEMAP_SRC" "$HEADER_DIR/module.modulemap"

export IPHONEOS_DEPLOYMENT_TARGET=14.0
export CMAKE_OSX_DEPLOYMENT_TARGET=14.0

cargo rustc --manifest-path "$RUST_DIR/Cargo.toml" --release --target aarch64-apple-ios --lib --crate-type staticlib
cargo rustc --manifest-path "$RUST_DIR/Cargo.toml" --release --target aarch64-apple-ios-sim --lib --crate-type staticlib
cargo rustc --manifest-path "$RUST_DIR/Cargo.toml" --release --target x86_64-apple-ios --lib --crate-type staticlib

cp "$RUST_DIR/target/aarch64-apple-ios/release/$LIB_NAME" "$ROOT/build/core_uniffi/ios/$LIB_NAME"

lipo -create \
  "$RUST_DIR/target/aarch64-apple-ios-sim/release/$LIB_NAME" \
  "$RUST_DIR/target/x86_64-apple-ios/release/$LIB_NAME" \
  -output "$ROOT/build/core_uniffi/ios-sim/$LIB_NAME"

rm -rf "$XCFRAMEWORK_OUT"

xcodebuild -create-xcframework \
  -library "$ROOT/build/core_uniffi/ios/$LIB_NAME" -headers "$HEADER_DIR" \
  -library "$ROOT/build/core_uniffi/ios-sim/$LIB_NAME" -headers "$HEADER_DIR" \
  -output "$XCFRAMEWORK_OUT"

echo "Built xcframework: $XCFRAMEWORK_OUT"
