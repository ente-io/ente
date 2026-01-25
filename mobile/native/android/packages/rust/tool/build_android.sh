#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT/../../../../.." && pwd)"
INFERENCE_UNIFFI_RUST_DIR="$REPO_ROOT/rust/inference_rs_uniffi"
CHATDB_UNIFFI_RUST_DIR="$REPO_ROOT/rust/llmchat_db_uniffi"
CHAT_SYNC_UNIFFI_RUST_DIR="$REPO_ROOT/rust/llmchat_sync_uniffi"
# Patch llama.cpp mtmd sources so mmproj models load correctly.
PATCH_SCRIPT="$REPO_ROOT/rust/inference_rs/tool/patch_llama_mtmd.sh"
APPLY_LLAMA_MTMD_PATCH="${APPLY_LLAMA_MTMD_PATCH:-1}"
OUT_DIR="$ROOT/src/main/jniLibs"
SDK_ROOT="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
NDK_VERSION="${NDK_VERSION:-}"
NDK_ROOT_PATH=""

if [[ -z "$SDK_ROOT" ]]; then
  for candidate in "$HOME/Library/Android/sdk" "$HOME/Android/Sdk" "$HOME/Android/sdk"; do
    if [[ -d "$candidate" ]]; then
      SDK_ROOT="$candidate"
      break
    fi
  done
fi

if [[ -z "$SDK_ROOT" ]]; then
  echo "Android SDK not found. Set ANDROID_HOME or ANDROID_SDK_ROOT to your SDK path." >&2
  exit 1
fi

if [[ -n "$NDK_VERSION" ]]; then
  NDK_ROOT_PATH="$SDK_ROOT/ndk/$NDK_VERSION"
elif [[ -d "$SDK_ROOT/ndk" ]]; then
  NDK_ROOT_PATH="$(ls -1d "$SDK_ROOT/ndk/"* 2>/dev/null | sort -V | tail -n 1)"
elif [[ -d "$SDK_ROOT/ndk-bundle" ]]; then
  NDK_ROOT_PATH="$SDK_ROOT/ndk-bundle"
fi

if [[ -z "$NDK_ROOT_PATH" || ! -d "$NDK_ROOT_PATH" ]]; then
  echo "Android NDK not found. Install an NDK under $SDK_ROOT/ndk or set NDK_VERSION to a specific version." >&2
  exit 1
fi

if [[ "$APPLY_LLAMA_MTMD_PATCH" != "0" && -f "$PATCH_SCRIPT" ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to apply the llama mtmd patch." >&2
    exit 1
  fi
  echo "Applying llama mtmd patch..."
  bash "$PATCH_SCRIPT"
fi

export ANDROID_NDK="$NDK_ROOT_PATH"
export ANDROID_NDK_ROOT="$NDK_ROOT_PATH"
export NDK_ROOT="$NDK_ROOT_PATH"
export CARGO_CFG_TARGET_FEATURE="${CARGO_CFG_TARGET_FEATURE:-}"

mkdir -p "$OUT_DIR"

for CRATE_DIR in "$INFERENCE_UNIFFI_RUST_DIR" "$CHATDB_UNIFFI_RUST_DIR" "$CHAT_SYNC_UNIFFI_RUST_DIR"; do
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
