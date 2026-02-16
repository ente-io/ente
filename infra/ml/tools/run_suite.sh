#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ML_DIR="$ROOT_DIR/infra/ml"
MANIFEST_PATH="$ROOT_DIR/infra/ml/ground_truth/manifest.json"
TEST_DATA_DIR="$ML_DIR/test_data/ml-indexing/v1"

SUITE="smoke"
PLATFORMS="all"
UPDATE_GOLDEN=false
FAIL_ON_MISSING_PLATFORM=false
OUTPUT_DIR="$ROOT_DIR/infra/ml/out/parity"

usage() {
  cat <<EOF
Usage: infra/ml/tools/run_suite.sh [flags]

Flags:
  --suite smoke|full
  --platforms all|desktop|android|ios
  --update-golden
  --fail-on-missing-platform
  --output-dir <path>
EOF
}

while (($# > 0)); do
  case "$1" in
    --suite)
      SUITE="$2"
      shift 2
      ;;
    --platforms)
      PLATFORMS="$2"
      shift 2
      ;;
    --update-golden)
      UPDATE_GOLDEN=true
      shift
      ;;
    --fail-on-missing-platform)
      FAIL_ON_MISSING_PLATFORM=true
      shift
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown flag: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ "$OUTPUT_DIR" != /* ]]; then
  OUTPUT_DIR="$ROOT_DIR/$OUTPUT_DIR"
fi

mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd -P)"
PYTHON_OUTPUT_DIR="$OUTPUT_DIR/python"
mkdir -p "$PYTHON_OUTPUT_DIR"

echo "Running ML parity suite"
echo "  suite: $SUITE"
echo "  platforms: $PLATFORMS"
echo "  output_dir: $OUTPUT_DIR"

echo "Preparing local fixture directory: $TEST_DATA_DIR"
rm -rf "$TEST_DATA_DIR"
mkdir -p "$TEST_DATA_DIR"

downloaded_count=0
while IFS=$'\t' read -r source_rel source_url source_sha; do
  if [[ -z "$source_rel" ]]; then
    continue
  fi
  if [[ -z "$source_url" ]]; then
    echo "Manifest item missing source_url for source=$source_rel" >&2
    exit 1
  fi

  target_path="$ML_DIR/$source_rel"
  target_dir="$(dirname "$target_path")"
  mkdir -p "$target_dir"

  tmp_path="$target_path.tmp"
  curl -fsSL --retry 3 --retry-delay 1 "$source_url" -o "$tmp_path"
  mv "$tmp_path" "$target_path"

  if [[ -n "$source_sha" ]]; then
    actual_sha="$(shasum -a 256 "$target_path" | awk '{print $1}')"
    if [[ "$actual_sha" != "$source_sha" ]]; then
      echo "SHA-256 mismatch for $source_rel: expected $source_sha got $actual_sha" >&2
      exit 1
    fi
  fi
  downloaded_count=$((downloaded_count + 1))
done < <(
  python3 - "$MANIFEST_PATH" <<'PY'
import json
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
manifest = json.loads(manifest_path.read_text())
items = manifest.get("items", [])
for item in items:
    source = str(item.get("source", "")).strip()
    source_url = str(item.get("source_url", "")).strip()
    source_sha = str(item.get("source_sha256", "")).strip()
    print(f"{source}\t{source_url}\t{source_sha}")
PY
)
echo "Downloaded fixture files: $downloaded_count"

echo "Generating Python goldens"
uv run --project "$ML_DIR" --no-sync python "$ML_DIR/tools/generate_goldens.py" \
  --manifest "infra/ml/ground_truth/manifest.json" \
  --output-dir "$PYTHON_OUTPUT_DIR"

declare -a selected_platforms=()
case "$PLATFORMS" in
  all)
    selected_platforms=(desktop android ios)
    ;;
  desktop|android|ios)
    selected_platforms=("$PLATFORMS")
    ;;
  *)
    echo "Unsupported --platforms value: $PLATFORMS" >&2
    exit 1
    ;;
esac

declare -a compare_args=()
missing_platform_count=0

for platform in "${selected_platforms[@]}"; do
  platform_output="$OUTPUT_DIR/$platform/results.json"
  if [[ -f "$platform_output" ]]; then
    compare_args+=(--platform-result "$platform=$platform_output")
    echo "Using existing $platform output: $platform_output"
  else
    echo "Platform output unavailable for $platform at $platform_output"
    missing_platform_count=$((missing_platform_count + 1))
  fi
done

if $FAIL_ON_MISSING_PLATFORM && ((missing_platform_count > 0)); then
  echo "Missing platform outputs and --fail-on-missing-platform is set" >&2
  exit 1
fi

compare_output="$OUTPUT_DIR/comparison_report.json"
compare_cmd=(
  uv run --project "$ML_DIR" --no-sync python "$ML_DIR/tools/compare_parity_outputs.py"
  --ground-truth "$PYTHON_OUTPUT_DIR/results.json"
  --output "$compare_output"
)
if ((${#compare_args[@]} > 0)); then
  compare_cmd+=("${compare_args[@]}")
fi

set +e
"${compare_cmd[@]}"
compare_exit=$?
set -e

echo "Comparison report: $compare_output"

if ((compare_exit != 0)); then
  echo "Parity comparison failed"
  exit "$compare_exit"
fi

echo "Parity comparison passed"
if $UPDATE_GOLDEN; then
  echo "--update-golden currently regenerates Python bootstrap goldens only."
fi
