#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
ML_DIR="$ROOT_DIR/infra/ml"

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

mkdir -p "$OUTPUT_DIR"
PYTHON_OUTPUT_DIR="$OUTPUT_DIR/python"
mkdir -p "$PYTHON_OUTPUT_DIR"

echo "Running ML parity suite"
echo "  suite: $SUITE"
echo "  platforms: $PLATFORMS"
echo "  output_dir: $OUTPUT_DIR"

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
