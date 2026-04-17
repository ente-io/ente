#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT/../../../../.." && pwd)"
RUST_DIR="$REPO_ROOT/rust/uniffi/ensu/inference"
CORE_ROOT="$REPO_ROOT/rust/ensu/inference"
PATCH_SCRIPT="$CORE_ROOT/tool/patch_llama_mtmd.sh"
APPLY_LLAMA_MTMD_PATCH="${APPLY_LLAMA_MTMD_PATCH:-1}"
OUT_DIR="$ROOT/Sources/InferenceRS"

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

require_compatible_uniffi_bindgen() {
  require_command cargo "Install Rust and ensure cargo is on PATH."

  if command -v uniffi-bindgen >/dev/null 2>&1; then
    local version
    version="$(uniffi-bindgen --version 2>/dev/null || true)"
    if printf "%s" "$version" | grep -q "0.31."; then
      return
    fi
    echo "Found incompatible ${version:-uniffi-bindgen version}." >&2
  else
    echo "Missing required command: uniffi-bindgen" >&2
  fi

  echo "Install a compatible version with:" >&2
  echo "  cargo install --locked --version 0.31.0 uniffi --features cli --bin uniffi-bindgen" >&2
  exit 1
}

require_command cargo "Install Rust and ensure cargo is on PATH."
require_compatible_uniffi_bindgen

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

LIB_PATH="$RUST_DIR/target/release/libinference.$LIB_EXT"

if [[ ! -f "$LIB_PATH" ]]; then
  echo "Expected $LIB_PATH to exist" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/inference* "$OUT_DIR"/inference_rs_uniffi*

pushd "$RUST_DIR" >/dev/null
uniffi-bindgen generate "$LIB_PATH" --language swift --out-dir "$OUT_DIR" --crate inference
popd >/dev/null
