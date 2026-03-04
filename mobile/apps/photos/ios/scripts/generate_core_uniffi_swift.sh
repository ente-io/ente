#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ROOT/../../../.." && pwd)"
RUST_DIR="$REPO_ROOT/rust/uniffi/core"
OUT_DIR="$ROOT/Runner/Generated/CoreUniFFI"

if ! command -v cargo >/dev/null 2>&1; then
  echo "cargo not found. Install Rust toolchain (https://rustup.rs)." >&2
  exit 1
fi

if ! command -v uniffi-bindgen >/dev/null 2>&1; then
  echo "uniffi-bindgen not found. Install with: cargo install uniffi_bindgen_cli" >&2
  exit 1
fi

cargo build --manifest-path "$RUST_DIR/Cargo.toml" --release

if [[ "$(uname -s)" == "Darwin" ]]; then
  LIB_EXT="dylib"
elif [[ "$(uname -s)" == "Linux" ]]; then
  LIB_EXT="so"
else
  LIB_EXT="dll"
fi

LIB_PATH="$RUST_DIR/target/release/libcore.$LIB_EXT"

if [[ ! -f "$LIB_PATH" ]]; then
  echo "Expected $LIB_PATH to exist" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/core*

pushd "$RUST_DIR" >/dev/null
uniffi-bindgen generate "$LIB_PATH" --language swift --out-dir "$OUT_DIR" --crate core
popd >/dev/null

echo "Generated Swift bindings in: $OUT_DIR"
