#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT/../../../../.." && pwd)"
RUST_DIR="$ROOT/rust"
CORE_ROOT="$REPO_ROOT/rust/inference_rs"
PATCH_SCRIPT="$CORE_ROOT/tool/patch_llama_mtmd.sh"
APPLY_LLAMA_MTMD_PATCH="${APPLY_LLAMA_MTMD_PATCH:-1}"
OUT_DIR="$ROOT/Sources/InferenceRS"

if [[ "$APPLY_LLAMA_MTMD_PATCH" != "0" && -f "$PATCH_SCRIPT" ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to apply the llama mtmd patch." >&2
    exit 1
  fi
  echo "Applying llama mtmd patch..."
  bash "$PATCH_SCRIPT"
fi

cargo build --manifest-path "$RUST_DIR/Cargo.toml" --release

if [[ "$(uname -s)" == "Darwin" ]]; then
  LIB_EXT="dylib"
elif [[ "$(uname -s)" == "Linux" ]]; then
  LIB_EXT="so"
else
  LIB_EXT="dll"
fi

LIB_PATH="$RUST_DIR/target/release/libinference_rs_uniffi.$LIB_EXT"

if [[ ! -f "$LIB_PATH" ]]; then
  echo "Expected $LIB_PATH to exist" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/inference_rs_*

pushd "$RUST_DIR" >/dev/null
uniffi-bindgen generate "$LIB_PATH" --language swift --out-dir "$OUT_DIR" --crate inference_rs_uniffi
popd >/dev/null
