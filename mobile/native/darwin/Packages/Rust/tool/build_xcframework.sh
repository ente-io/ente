#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT/../../../../.." && pwd)"
RUST_DIR="$REPO_ROOT/rust/uniffi/ensu/inference"
CORE_ROOT="$REPO_ROOT/rust/ensu/inference"
PATCH_SCRIPT="$CORE_ROOT/tool/patch_llama_mtmd.sh"
APPLY_LLAMA_MTMD_PATCH="${APPLY_LLAMA_MTMD_PATCH:-1}"
LIB_NAME="libinference.a"

require_command() {
  local name="$1"
  local hint="${2:-}"
  if command -v "$name" >/dev/null 2>&1; then
    return
  fi

  echo "Missing required command: $name" >&2
  if [[ -n "$hint" ]]; then
    echo "$hint" >&2
  fi
  exit 1
}

require_command cargo "Install Rust and ensure cargo is on PATH."
require_command rustup "Install rustup and ensure it is on PATH."
require_command xcodebuild "Install Xcode command line tools and ensure xcodebuild is on PATH."
require_command lipo "Install Xcode command line tools and ensure lipo is on PATH."
require_command cmake "Install CMake, for example with 'brew install cmake'."
require_command uniffi-bindgen "Install a compatible version with 'cargo install --locked --version 0.31.0 uniffi --features cli --bin uniffi-bindgen'."

require_rust_target() {
  local target="$1"
  if rustup target list --installed | grep -qx "$target"; then
    return
  fi

  echo "Missing required Rust target: $target" >&2
  echo "Install Apple targets with:" >&2
  echo "  rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios aarch64-apple-darwin x86_64-apple-darwin" >&2
  exit 1
}

require_rust_target aarch64-apple-ios
require_rust_target aarch64-apple-ios-sim
require_rust_target x86_64-apple-ios
require_rust_target aarch64-apple-darwin
require_rust_target x86_64-apple-darwin

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
HEADER_SRC="$ROOT/Sources/InferenceRS/inferenceFFI.h"
MODULEMAP_SRC="$ROOT/Sources/InferenceRS/inferenceFFI.modulemap"

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
