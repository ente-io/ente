#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT/../../../../.." && pwd)"
CORE_UNIFFI_RUST_DIR="$REPO_ROOT/rust/uniffi/core"
INFERENCE_UNIFFI_RUST_DIR="$REPO_ROOT/rust/uniffi/ensu/inference"
CHATDB_UNIFFI_RUST_DIR="$REPO_ROOT/rust/uniffi/ensu/db"
CHAT_SYNC_UNIFFI_RUST_DIR="$REPO_ROOT/rust/uniffi/ensu/sync"
OUT_DIR="$ROOT/build/generated/jniLibs"
SDK_ROOT="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
NDK_VERSION="${NDK_VERSION:-}"
NDK_ROOT_PATH=""
TOOLCHAIN_BIN=""
HOST_TAG=""
ABIS=()

export PATH="${CARGO_HOME:-$HOME/.cargo}/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir)
      OUT_DIR="$2"
      shift 2
      ;;
    *)
      ABIS+=("$1")
      shift
      ;;
  esac
done

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

case "$(uname -s):$(uname -m)" in
  Darwin:arm64)
    HOST_TAG_CANDIDATES=(darwin-arm64 darwin-x86_64)
    ;;
  Darwin:x86_64)
    HOST_TAG_CANDIDATES=(darwin-x86_64)
    ;;
  Linux:aarch64 | Linux:arm64)
    HOST_TAG_CANDIDATES=(linux-aarch64)
    ;;
  Linux:x86_64)
    HOST_TAG_CANDIDATES=(linux-x86_64)
    ;;
  *)
    echo "Unsupported host for Android NDK builds: $(uname -s):$(uname -m)" >&2
    exit 1
    ;;
esac

for host_tag in "${HOST_TAG_CANDIDATES[@]}"; do
  candidate="$NDK_ROOT_PATH/toolchains/llvm/prebuilt/$host_tag/bin"
  if [[ -d "$candidate" ]]; then
    HOST_TAG="$host_tag"
    TOOLCHAIN_BIN="$candidate"
    break
  fi
done

if [[ -z "$TOOLCHAIN_BIN" ]]; then
  echo "Android NDK LLVM toolchain not found under $NDK_ROOT_PATH/toolchains/llvm/prebuilt" >&2
  exit 1
fi

export ANDROID_NDK="$NDK_ROOT_PATH"
export ANDROID_NDK_ROOT="$NDK_ROOT_PATH"
export NDK_ROOT="$NDK_ROOT_PATH"
export PATH="$TOOLCHAIN_BIN:$PATH"

mkdir -p "$OUT_DIR"

if [[ ${#ABIS[@]} -eq 0 ]]; then
  echo "Usage: build_android.sh [--out-dir DIR] <abi> [<abi>...]" >&2
  exit 1
fi

rust_target_for_abi() {
  case "$1" in
    arm64-v8a) echo aarch64-linux-android ;;
    armeabi-v7a) echo armv7-linux-androideabi ;;
    x86_64) echo x86_64-linux-android ;;
    *) return 1 ;;
  esac
}

toolchain_for_abi() {
  case "$1" in
    arm64-v8a) echo aarch64-linux-android23 ;;
    armeabi-v7a) echo armv7a-linux-androideabi23 ;;
    x86_64) echo x86_64-linux-android23 ;;
    *) return 1 ;;
  esac
}

libcxx_dir_for_abi() {
  case "$1" in
    arm64-v8a) echo aarch64-linux-android ;;
    armeabi-v7a) echo arm-linux-androideabi ;;
    x86_64) echo x86_64-linux-android ;;
    *) return 1 ;;
  esac
}

build_abi() {
  local abi="$1"
  local target clang_triple libcxx_dir linker clangxx suffix

  target=$(rust_target_for_abi "$abi") || {
    echo "Unsupported Android ABI: $abi" >&2
    exit 1
  }
  clang_triple=$(toolchain_for_abi "$abi")
  libcxx_dir=$(libcxx_dir_for_abi "$abi")
  linker="$TOOLCHAIN_BIN/$clang_triple-clang"
  clangxx="$TOOLCHAIN_BIN/$clang_triple-clang++"
  suffix=$(echo "$target" | tr '[:lower:]-' '[:upper:]_')

  [[ -x "$linker" ]] || { echo "Expected linker $linker" >&2; exit 1; }
  [[ -x "$clangxx" ]] || { echo "Expected linker $clangxx" >&2; exit 1; }

  rustup target list --installed | grep -qx "$target" \
    || rustup target add "$target"

  export "CARGO_TARGET_${suffix}_LINKER=$linker"
  export "CC_${target//-/_}=$linker"
  export "CXX_${target//-/_}=$clangxx"
  export "AR_${target//-/_}=$TOOLCHAIN_BIN/llvm-ar"
  export "RANLIB_${target//-/_}=$TOOLCHAIN_BIN/llvm-ranlib"

  for CRATE_DIR in "$CORE_UNIFFI_RUST_DIR" "$INFERENCE_UNIFFI_RUST_DIR" "$CHATDB_UNIFFI_RUST_DIR" "$CHAT_SYNC_UNIFFI_RUST_DIR"; do
    pushd "$CRATE_DIR" >/dev/null
    cargo build --release --target "$target"

    lib_name=$(basename "$CRATE_DIR")
    built_lib="$CRATE_DIR/target/$target/release/lib${lib_name}.so"
    [[ -f "$built_lib" ]] || { echo "Expected $built_lib" >&2; exit 1; }

    mkdir -p "$OUT_DIR/$abi"
    cp "$built_lib" "$OUT_DIR/$abi/"
    popd >/dev/null
  done

  libcxx_shared="$NDK_ROOT_PATH/toolchains/llvm/prebuilt/$HOST_TAG/sysroot/usr/lib/$libcxx_dir/libc++_shared.so"
  [[ -f "$libcxx_shared" ]] || { echo "Expected $libcxx_shared" >&2; exit 1; }
  cp "$libcxx_shared" "$OUT_DIR/$abi/"
}

rm -rf \
  "$OUT_DIR/arm64-v8a" \
  "$OUT_DIR/armeabi-v7a" \
  "$OUT_DIR/x86_64"

for abi in "${ABIS[@]}"; do
  build_abi "$abi"
done
