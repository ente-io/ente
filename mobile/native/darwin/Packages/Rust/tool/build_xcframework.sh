#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT/../../../../.." && pwd)"
RUST_DIR="$ROOT/rust"
CORE_ROOT="$REPO_ROOT/rust/ensu/inference"
PATCH_SCRIPT="$CORE_ROOT/tool/patch_llama_mtmd.sh"
APPLY_LLAMA_MTMD_PATCH="${APPLY_LLAMA_MTMD_PATCH:-1}"
LIB_NAME="libinference_rs_uniffi.a"

if [[ "$APPLY_LLAMA_MTMD_PATCH" != "0" && -f "$PATCH_SCRIPT" ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to apply the llama mtmd patch." >&2
    exit 1
  fi
  echo "Applying llama mtmd patch..."
  bash "$PATCH_SCRIPT"
fi

"$ROOT/tool/generate_bindings.sh"

HEADER_DIR="$ROOT/build/headers"
HEADER_SRC="$ROOT/Sources/InferenceRS/inference_rs_uniffiFFI.h"
MODULEMAP_SRC="$ROOT/Sources/InferenceRS/inference_rs_uniffiFFI.modulemap"

rm -rf "$HEADER_DIR"
mkdir -p "$ROOT/build/ios" "$ROOT/build/macos" "$HEADER_DIR"

if [[ ! -f "$HEADER_SRC" ]] || [[ ! -f "$MODULEMAP_SRC" ]]; then
  echo "Expected UniFFI headers in $ROOT/Sources/InferenceRS" >&2
  exit 1
fi

cp "$HEADER_SRC" "$HEADER_DIR/"
cp "$MODULEMAP_SRC" "$HEADER_DIR/module.modulemap"

export IPHONEOS_DEPLOYMENT_TARGET=13.0
export CMAKE_OSX_DEPLOYMENT_TARGET=13.0

cargo rustc --manifest-path "$RUST_DIR/Cargo.toml" --release --target aarch64-apple-ios --lib --crate-type staticlib
cargo rustc --manifest-path "$RUST_DIR/Cargo.toml" --release --target aarch64-apple-ios-sim --lib --crate-type staticlib
cargo rustc --manifest-path "$RUST_DIR/Cargo.toml" --release --target x86_64-apple-ios --lib --crate-type staticlib

cp "$RUST_DIR/target/aarch64-apple-ios/release/$LIB_NAME" "$ROOT/build/ios/$LIB_NAME"

lipo -create \
  "$RUST_DIR/target/aarch64-apple-ios-sim/release/$LIB_NAME" \
  "$RUST_DIR/target/x86_64-apple-ios/release/$LIB_NAME" \
  -output "$ROOT/build/ios/${LIB_NAME%.a}-sim.a"

unset IPHONEOS_DEPLOYMENT_TARGET
export MACOSX_DEPLOYMENT_TARGET=10.15
export CMAKE_OSX_DEPLOYMENT_TARGET=10.15

cargo rustc --manifest-path "$RUST_DIR/Cargo.toml" --release --target aarch64-apple-darwin --lib --crate-type staticlib
cargo rustc --manifest-path "$RUST_DIR/Cargo.toml" --release --target x86_64-apple-darwin --lib --crate-type staticlib

lipo -create \
  "$RUST_DIR/target/aarch64-apple-darwin/release/$LIB_NAME" \
  "$RUST_DIR/target/x86_64-apple-darwin/release/$LIB_NAME" \
  -output "$ROOT/build/macos/$LIB_NAME"

rm -rf "$ROOT/InferenceRSFFI.xcframework"

xcodebuild -create-xcframework \
  -library "$ROOT/build/ios/$LIB_NAME" -headers "$HEADER_DIR" \
  -library "$ROOT/build/ios/${LIB_NAME%.a}-sim.a" -headers "$HEADER_DIR" \
  -library "$ROOT/build/macos/$LIB_NAME" -headers "$HEADER_DIR" \
  -output "$ROOT/InferenceRSFFI.xcframework"
