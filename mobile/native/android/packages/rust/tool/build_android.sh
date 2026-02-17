#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT/../../../../.." && pwd)"
CORE_UNIFFI_RUST_DIR="$REPO_ROOT/rust/uniffi/core"
INFERENCE_UNIFFI_RUST_DIR="$REPO_ROOT/rust/uniffi/ensu/inference"
CHATDB_UNIFFI_RUST_DIR="$REPO_ROOT/rust/uniffi/ensu/db"
CHAT_SYNC_UNIFFI_RUST_DIR="$REPO_ROOT/rust/uniffi/ensu/sync"
# Patch llama.cpp mtmd sources so mmproj models load correctly.
PATCH_SCRIPT="$REPO_ROOT/rust/ensu/inference/tool/patch_llama_mtmd.sh"
APPLY_LLAMA_MTMD_PATCH="${APPLY_LLAMA_MTMD_PATCH:-1}"
OUT_DIR="$ROOT/src/main/jniLibs"
CORE_KOTLIN_OUT_DIR="$REPO_ROOT/mobile/native/android/apps/ensu/crypto-auth-core/src/main/java"
RUST_KOTLIN_OUT_DIR="$ROOT/src/main/kotlin"
SDK_ROOT="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
NDK_VERSION="${NDK_VERSION:-}"
NDK_ROOT_PATH=""

if [[ "$(uname -s)" == "Darwin" ]]; then
  HOST_LIB_EXT="dylib"
elif [[ "$(uname -s)" == "Linux" ]]; then
  HOST_LIB_EXT="so"
else
  HOST_LIB_EXT="dll"
fi

ensure_uniffi_bindgen() {
  if command -v uniffi-bindgen >/dev/null 2>&1; then
    local version
    version="$(uniffi-bindgen --version 2>/dev/null || true)"
    if [[ "$version" == *"0.31."* ]]; then
      return
    fi
    echo "Found incompatible $version, installing uniffi-bindgen 0.31.x"
  fi

  cargo install --locked --version 0.31.0 uniffi --features cli --bin uniffi-bindgen
}

generate_kotlin_bindings() {
  local crate_dir="$1"
  local lib_name="$2"
  local out_dir="$3"

  pushd "$crate_dir" >/dev/null
  cargo build --release

  local lib_path="$crate_dir/target/release/lib${lib_name}.${HOST_LIB_EXT}"
  if [[ ! -f "$lib_path" ]]; then
    echo "Expected $lib_path to exist" >&2
    exit 1
  fi

  mkdir -p "$out_dir"
  uniffi-bindgen generate "$lib_path" --language kotlin --out-dir "$out_dir"
  popd >/dev/null
}

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
  # Prefer numeric version folders (ignore legacy rXX folders).
  NDK_ROOT_PATH="$(find "$SDK_ROOT/ndk" -mindepth 1 -maxdepth 1 -name '[0-9]*' 2>/dev/null | sort -V | tail -n 1 || true)"
  if [[ -z "$NDK_ROOT_PATH" ]]; then
    NDK_ROOT_PATH="$(find "$SDK_ROOT/ndk" -mindepth 1 -maxdepth 1 2>/dev/null | sort -V | tail -n 1 || true)"
  fi
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

for CRATE_DIR in "$CORE_UNIFFI_RUST_DIR" "$INFERENCE_UNIFFI_RUST_DIR" "$CHATDB_UNIFFI_RUST_DIR" "$CHAT_SYNC_UNIFFI_RUST_DIR"; do
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

ensure_uniffi_bindgen

# Remove stale generated bindings to avoid duplicate symbol conflicts.
rm -f "$CORE_KOTLIN_OUT_DIR/io/ente/ensu/crypto/core.kt"
rm -f "$RUST_KOTLIN_OUT_DIR/io/ente/labs/inference_rs/inference.kt"
rm -f "$RUST_KOTLIN_OUT_DIR/io/ente/labs/inference_rs/inference_rs_uniffi.kt"
rm -f "$RUST_KOTLIN_OUT_DIR/io/ente/labs/ensu_db/db.kt"
rm -f "$RUST_KOTLIN_OUT_DIR/io/ente/labs/llmchat_db/llmchat_db_uniffi.kt"
rm -f "$RUST_KOTLIN_OUT_DIR/io/ente/labs/ensu_sync/sync.kt"
rm -f "$RUST_KOTLIN_OUT_DIR/io/ente/labs/llmchat_sync/llmchat_sync_uniffi.kt"

generate_kotlin_bindings "$CORE_UNIFFI_RUST_DIR" "core" "$CORE_KOTLIN_OUT_DIR"
generate_kotlin_bindings "$INFERENCE_UNIFFI_RUST_DIR" "inference" "$RUST_KOTLIN_OUT_DIR"
generate_kotlin_bindings "$CHATDB_UNIFFI_RUST_DIR" "db" "$RUST_KOTLIN_OUT_DIR"
generate_kotlin_bindings "$CHAT_SYNC_UNIFFI_RUST_DIR" "sync" "$RUST_KOTLIN_OUT_DIR"
