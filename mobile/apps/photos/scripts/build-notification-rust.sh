#!/bin/bash
set -euo pipefail

REPO_ROOT=$(cd "$SRCROOT/../../../.." && pwd)
OUT_DIR="$TARGET_TEMP_DIR/notification_rust"
export PATH="${CARGO_HOME:-$HOME/.cargo}/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
export SDKROOT
export IPHONEOS_DEPLOYMENT_TARGET

case "$CONFIGURATION" in
  Release|Profile) profile=release; cargo_flags=(--locked --release) ;;
  *) profile=debug; cargo_flags=(--locked) ;;
esac

mkdir -p "$OUT_DIR"
libs=()
for arch in $ARCHS; do
  case "$PLATFORM_NAME:$arch" in
    iphoneos:arm64) target=aarch64-apple-ios ;;
    iphonesimulator:arm64) target=aarch64-apple-ios-sim ;;
    iphonesimulator:x86_64) target=x86_64-apple-ios ;;
    *) echo "error: unsupported notification extension target: $PLATFORM_NAME/$arch" >&2; exit 1 ;;
  esac
  rustup target list --installed | grep -qx "$target" || rustup target add "$target"
  (cd "$REPO_ROOT/rust" && cargo build -p ente-notification-ffi --lib \
    --target-dir "$REPO_ROOT/rust/target" --target "$target" "${cargo_flags[@]}")
  cp "$REPO_ROOT/rust/target/$target/$profile/libente_notification_ffi.a" "$OUT_DIR/$arch.a"
  libs+=("$OUT_DIR/$arch.a")
done
if [ "${#libs[@]}" -eq 1 ]; then
  cp "${libs[0]}" "$OUT_DIR/libente_notification_ffi.a"
else
  lipo -create "${libs[@]}" -output "$OUT_DIR/libente_notification_ffi.a"
fi
