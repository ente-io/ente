#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT/../../../../.." && pwd)"
INFERENCE_UNIFFI_RUST_DIR="$REPO_ROOT/rust/inference_rs_uniffi"
CHATDB_UNIFFI_RUST_DIR="$REPO_ROOT/rust/llmchat_db_uniffi"
# Note: Older builds used to patch llama-cpp sources; this repo no longer ships that patch script.
PATCH_SCRIPT=""
OUT_DIR="$ROOT/src/main/jniLibs"
NDK_VERSION="27.0.12077973"
NDK_ROOT_PATH="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}/ndk/$NDK_VERSION"

if [[ -z "${ANDROID_HOME:-}" && -z "${ANDROID_SDK_ROOT:-}" ]]; then
  echo "ANDROID_HOME or ANDROID_SDK_ROOT must be set" >&2
  exit 1
fi

if [[ ! -d "$NDK_ROOT_PATH" ]]; then
  echo "Android NDK not found at $NDK_ROOT_PATH" >&2
  exit 1
fi


export ANDROID_NDK="$NDK_ROOT_PATH"
export ANDROID_NDK_ROOT="$NDK_ROOT_PATH"
export NDK_ROOT="$NDK_ROOT_PATH"
export CARGO_CFG_TARGET_FEATURE="${CARGO_CFG_TARGET_FEATURE:-}"

mkdir -p "$OUT_DIR"

for CRATE_DIR in "$INFERENCE_UNIFFI_RUST_DIR" "$CHATDB_UNIFFI_RUST_DIR"; do
  pushd "$CRATE_DIR" >/dev/null
  cargo ndk \
    --platform 23 \
    --link-libcxx-shared \
    -t arm64-v8a \
    -t armeabi-v7a \
    -t x86_64 \
    -o "$OUT_DIR" \
    build --release
  popd >/dev/null
done
