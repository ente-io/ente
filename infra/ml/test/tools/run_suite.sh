#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(
  git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel 2>/dev/null \
    || (cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
)"
ML_DIR="$ROOT_DIR/infra/ml/test"
UV_PROJECT_DIR="$ROOT_DIR/infra/ml"
MANIFEST_PATH="$ROOT_DIR/infra/ml/test/ground_truth/manifest.json"
TEST_DATA_DIR="$ML_DIR/test_data/ml-indexing/v1"

SUITE="smoke"
PLATFORMS="all"
UPDATE_GOLDEN=false
FAIL_ON_MISSING_PLATFORM=false
FAIL_ON_PLATFORM_RUNNER_ERROR=false
ALLOW_EMPTY_COMPARISON=false
OUTPUT_DIR="$ROOT_DIR/infra/ml/test/out/parity"
VERBOSE=false

usage() {
  cat <<EOF
Usage: infra/ml/test/tools/run_suite.sh [flags]

Flags:
  --suite smoke|full
  --platforms all|desktop|android|ios
  --update-golden
  --fail-on-missing-platform
  --fail-on-platform-runner-error
  --allow-empty-comparison
  --output-dir <path>
  --verbose
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
    --fail-on-platform-runner-error)
      FAIL_ON_PLATFORM_RUNNER_ERROR=true
      shift
      ;;
    --allow-empty-comparison)
      ALLOW_EMPTY_COMPARISON=true
      shift
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
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
LOG_DIR="$OUTPUT_DIR/logs"
rm -rf "$LOG_DIR"
mkdir -p "$LOG_DIR"
PLATFORM_LOG_DIR="$LOG_DIR/platforms"
mkdir -p "$PLATFORM_LOG_DIR"
PYTHON_OUTPUT_DIR="$OUTPUT_DIR/python"
rm -rf "$PYTHON_OUTPUT_DIR"
mkdir -p "$PYTHON_OUTPUT_DIR"
MANIFEST_B64="$(
  python3 - "$MANIFEST_PATH" <<'PY'
import base64
import pathlib
import sys

manifest_path = pathlib.Path(sys.argv[1])
print(base64.b64encode(manifest_path.read_bytes()).decode("ascii"))
PY
)"
CODE_REVISION="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo local)"

echo "Running ML parity suite"
echo "  suite: $SUITE"
echo "  platforms: $PLATFORMS"
echo "  output_dir: $OUTPUT_DIR"
echo "  verbose: $VERBOSE"

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
    actual_sha="$(
      python3 - "$target_path" <<'PY'
import hashlib
import sys

path = sys.argv[1]
digest = hashlib.sha256()
with open(path, "rb") as file:
    for chunk in iter(lambda: file.read(1024 * 1024), b""):
        digest.update(chunk)
print(digest.hexdigest())
PY
    )"
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
goldens_log="$LOG_DIR/generate_goldens.log"
if $VERBOSE; then
  uv run --project "$UV_PROJECT_DIR" --no-sync --with pillow-heif python "$ML_DIR/tools/generate_goldens.py" \
    --manifest "infra/ml/test/ground_truth/manifest.json" \
    --output-dir "$PYTHON_OUTPUT_DIR"
else
  if ! uv run --project "$UV_PROJECT_DIR" --no-sync --with pillow-heif python "$ML_DIR/tools/generate_goldens.py" \
    --manifest "infra/ml/test/ground_truth/manifest.json" \
    --output-dir "$PYTHON_OUTPUT_DIR" >"$goldens_log" 2>&1; then
    echo "Python golden generation failed. Log: $goldens_log" >&2
    exit 1
  fi
fi

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

echo "Clearing stale platform output directories"
for platform in "${selected_platforms[@]}"; do
  platform_dir="$OUTPUT_DIR/$platform"
  rm -rf "$platform_dir"
  mkdir -p "$platform_dir"
done

run_desktop_runner() {
  local desktop_dir="$ROOT_DIR/desktop"
  local web_dir="$ROOT_DIR/web"
  local runner_path="$desktop_dir/scripts/ml_parity_runner.ts"
  local platform_output_dir="$OUTPUT_DIR/desktop"

  if [[ ! -f "$runner_path" ]]; then
    echo "Desktop parity runner not found at $runner_path; skipping desktop run."
    return 2
  fi

  if [[ ! -d "$desktop_dir/node_modules" ]]; then
    echo "Desktop dependencies are missing ($desktop_dir/node_modules); skipping desktop run."
    return 2
  fi

  if [[ ! -d "$web_dir/node_modules" ]]; then
    echo "Web dependencies are missing ($web_dir/node_modules); skipping desktop run."
    return 2
  fi

  if ! command -v npx >/dev/null 2>&1; then
    echo "npx is required to run the desktop parity runner; skipping desktop run."
    return 2
  fi

  echo "Compiling desktop TypeScript sources"
  if ! yarn --cwd "$desktop_dir" tsc; then
    echo "Desktop TypeScript compilation failed; desktop parity output not generated."
    return 1
  fi

  echo "Running desktop parity runner"
  if ! (
    cd "$web_dir"
    isDesktop=1 appName=photos desktopAppVersion=parity npx --yes tsx "$runner_path" \
      --manifest "$MANIFEST_PATH" \
      --output-dir "$platform_output_dir"
  ); then
    echo "Desktop parity runner failed; desktop parity output not generated."
    return 1
  fi

  return 0
}

platform_device_available() {
  local platform="$1"
  python3 - "$platform" <<'PY'
from __future__ import annotations

import json
import subprocess
import sys

platform = sys.argv[1]

try:
    raw = subprocess.check_output(
        ["flutter", "devices", "--machine"],
        stderr=subprocess.STDOUT,
        text=True,
    )
except Exception:
    sys.exit(2)

try:
    devices = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(2)

def is_match(device: dict[str, object]) -> bool:
    target = str(device.get("targetPlatform", "")).lower()
    name = str(device.get("name", "")).lower()
    if platform == "android":
        return "android" in target or "android" in name
    if platform == "ios":
        return "ios" in target or "iphone" in name or "ipad" in name
    return False

sys.exit(0 if any(is_match(device) for device in devices) else 1)
PY
}

platform_device_id() {
  local platform="$1"
  local selected
  selected="$(
    python3 - "$platform" <<'PY'
from __future__ import annotations

import json
import subprocess
import sys

platform = sys.argv[1]

try:
    raw = subprocess.check_output(
        ["flutter", "devices", "--machine"],
        stderr=subprocess.STDOUT,
        text=True,
    )
except Exception:
    sys.exit(2)

try:
    devices = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(2)

def is_match(device: dict[str, object]) -> bool:
    target = str(device.get("targetPlatform", "")).lower()
    name = str(device.get("name", "")).lower()
    if platform == "android":
        return "android" in target or "android" in name
    if platform == "ios":
        return "ios" in target or "iphone" in name or "ipad" in name
    return False

for device in devices:
    if is_match(device):
        print(device.get("id", ""))
        sys.exit(0)

sys.exit(1)
PY
  )"

  if [[ -n "$selected" ]]; then
    echo "$selected"
    return 0
  fi

  return 1
}

run_mobile_runner() {
  local platform="$1"
  local target="$2"
  local device_id="${3:-}"

  local mobile_dir="$ROOT_DIR/mobile/apps/photos"
  local driver_path="$mobile_dir/test_driver/ml_parity_driver.dart"
  local target_path="$mobile_dir/$target"
  local platform_output_dir="$OUTPUT_DIR/$platform"
  local output_path="$platform_output_dir/results.json"

  if [[ ! -f "$driver_path" ]]; then
    echo "Mobile parity driver not found at $driver_path; skipping $platform run."
    return 2
  fi

  if [[ ! -f "$target_path" ]]; then
    echo "Mobile parity test target not found at $target_path; skipping $platform run."
    return 2
  fi

  if ! command -v flutter >/dev/null 2>&1; then
    echo "flutter is required to run mobile parity; skipping $platform run."
    return 2
  fi

  if [[ -z "$device_id" ]]; then
    local platform_available_exit=0
    if platform_device_available "$platform"; then
      platform_available_exit=0
    else
      platform_available_exit=$?
    fi
    case "$platform_available_exit" in
      0)
        ;;
      1)
        echo "No connected $platform device/simulator detected; skipping $platform run."
        return 2
        ;;
      *)
        echo "Could not determine $platform device availability; skipping $platform run."
        return 2
        ;;
    esac
  fi

  if [[ ! -f "$mobile_dir/.dart_tool/package_config.json" ]]; then
    echo "Running flutter pub get for mobile app"
    if ! (cd "$mobile_dir" && flutter pub get); then
      echo "flutter pub get failed; $platform parity output not generated."
      return 1
    fi
  fi

  local flavor=""
  case "$platform" in
    android)
      flavor="${ML_PARITY_ANDROID_FLAVOR:-independent}"
      ;;
    ios)
      flavor="${ML_PARITY_IOS_FLAVOR:-}"
      ;;
  esac

  local -a drive_cmd=(
    flutter drive
    --driver=test_driver/ml_parity_driver.dart
    --target="$target"
  )
  if [[ -n "$flavor" ]]; then
    drive_cmd+=(--flavor "$flavor")
  fi
  drive_cmd+=(
    --no-dds
    --dart-define=ML_PARITY_MANIFEST_B64="$MANIFEST_B64"
    --dart-define=ML_PARITY_CODE_REVISION="$CODE_REVISION"
    --dart-define=ML_PARITY_SUITE="$SUITE"
  )
  if [[ -n "$device_id" ]]; then
    drive_cmd+=(-d "$device_id")
  else
    local selected_device_id
    if ! selected_device_id="$(platform_device_id "$platform")"; then
      echo "Could not resolve a connected $platform device; skipping $platform run."
      return 2
    fi
    drive_cmd+=(-d "$selected_device_id")
  fi

  echo "Running $platform parity runner"
  if ! (
    cd "$mobile_dir"
    ML_PARITY_DRIVER_OUTPUT="$output_path" "${drive_cmd[@]}"
  ); then
    echo "$platform parity runner failed; $platform parity output not generated."
    return 1
  fi

  if [[ ! -f "$output_path" ]]; then
    echo "$platform parity runner finished without output at $output_path."
    return 1
  fi

  return 0
}

run_android_runner() {
  run_mobile_runner \
    "android" \
    "integration_test/ml_parity_android_test.dart" \
    "${ML_PARITY_ANDROID_DEVICE_ID:-}"
}

run_ios_runner() {
  run_mobile_runner \
    "ios" \
    "integration_test/ml_parity_ios_test.dart" \
    "${ML_PARITY_IOS_DEVICE_ID:-}"
}

run_platform_runner() {
  local platform="$1"
  case "$platform" in
    desktop)
      run_desktop_runner
      ;;
    android)
      run_android_runner
      ;;
    ios)
      run_ios_runner
      ;;
    *)
      echo "Unknown platform: $platform" >&2
      return 1
      ;;
  esac
}

render_file_level_report_tables() {
  local report_path="$1"
  python3 - "$report_path" <<'PY'
from __future__ import annotations

import json
import sys
from collections import OrderedDict
from pathlib import Path

LOWER_IS_WORSE_METRICS = {"face_box_iou"}


def _fmt_float(value: float) -> str:
    return f"{value:.6f}"


def _summarize_metric_failures(metric: str, failures: list[dict[str, object]]) -> str:
    numeric_values = [
        float(value)
        for value in (failure.get("value") for failure in failures)
        if isinstance(value, (int, float))
    ]
    threshold_values = [
        float(threshold)
        for threshold in (failure.get("threshold") for failure in failures)
        if isinstance(threshold, (int, float))
    ]
    threshold = threshold_values[0] if threshold_values else None
    occurrence_count = len(failures)

    if numeric_values:
        if metric in LOWER_IS_WORSE_METRICS:
            worst_value = min(numeric_values)
            if threshold is None:
                return (
                    f"{metric} x{occurrence_count}: "
                    f"worst={_fmt_float(worst_value)}"
                )
            shortfall = threshold - worst_value
            return (
                f"{metric} x{occurrence_count}: "
                f"worst={_fmt_float(worst_value)} < {_fmt_float(threshold)} "
                f"(shortfall {_fmt_float(shortfall)})"
            )

        worst_value = max(numeric_values)
        if threshold is None:
            return (
                f"{metric} x{occurrence_count}: "
                f"worst={_fmt_float(worst_value)}"
            )
        overshoot = worst_value - threshold
        return (
            f"{metric} x{occurrence_count}: "
            f"worst={_fmt_float(worst_value)} > {_fmt_float(threshold)} "
            f"(overshoot {_fmt_float(overshoot)})"
        )

    message = str(failures[0].get("message", "threshold violation"))
    return f"{metric} x{occurrence_count}: {message}"


def _summarize_file_failures(failures: list[dict[str, object]]) -> str:
    if not failures:
        return "-"

    by_metric: "OrderedDict[str, list[dict[str, object]]]" = OrderedDict()
    for failure in failures:
        metric = str(failure.get("metric", "unknown_metric"))
        by_metric.setdefault(metric, []).append(failure)

    return "; ".join(
        _summarize_metric_failures(metric, metric_failures)
        for metric, metric_failures in by_metric.items()
    )


def _escape_cell(value: str) -> str:
    return value.replace("|", "\\|")


report_path = Path(sys.argv[1])
if not report_path.exists():
    print(f"Comparison report not found at {report_path}")
    raise SystemExit(0)

payload = json.loads(report_path.read_text())
ground_truth_platform = str(payload.get("ground_truth_platform", "python"))
comparisons = payload.get("comparisons", [])
if not isinstance(comparisons, list) or not comparisons:
    print("No platform comparisons were generated.")
    raise SystemExit(0)

printed_any_table = False
for comparison in comparisons:
    if not isinstance(comparison, dict):
        continue
    if comparison.get("reference_platform") != ground_truth_platform:
        continue

    candidate_platform = str(comparison.get("candidate_platform", "unknown"))
    file_summary = comparison.get("file_summary") or {}
    if not isinstance(file_summary, dict):
        file_summary = {}
    total_files = int(file_summary.get("total_reference_files", comparison.get("total_reference_files", 0)))
    pass_count = int(file_summary.get("pass_count", len(comparison.get("passing_files", []))))
    fail_count = int(file_summary.get("fail_count", len(comparison.get("failing_files", []))))

    file_statuses = comparison.get("file_statuses", [])
    if not isinstance(file_statuses, list):
        file_statuses = []

    rows: list[tuple[str, str, str]] = []
    if file_statuses:
        for file_status in file_statuses:
            if not isinstance(file_status, dict):
                continue
            file_id = str(file_status.get("file_id", ""))
            passed = bool(file_status.get("passed", False))
            failures = file_status.get("failures", [])
            if not isinstance(failures, list):
                failures = []
            status = "PASS" if passed else "FAIL"
            details = _summarize_file_failures(failures)
            rows.append((file_id, status, details))
    else:
        passing_files = [str(file_id) for file_id in comparison.get("passing_files", [])]
        failing_files = [str(file_id) for file_id in comparison.get("failing_files", [])]
        for file_id in passing_files:
            rows.append((file_id, "PASS", "-"))
        for file_id in failing_files:
            rows.append((file_id, "FAIL", "No failure detail available in report"))

    if not rows:
        continue

    rows.sort(key=lambda row: (row[1] == "PASS", row[0]))

    print()
    print(
        f"### {candidate_platform} vs {ground_truth_platform} "
        f"({pass_count} pass / {fail_count} fail / {total_files} total)"
    )
    print("| File | Status | Failure Details |")
    print("| --- | --- | --- |")
    for file_id, status, details in rows:
        print(
            "| "
            + " | ".join(
                (
                    _escape_cell(file_id),
                    status,
                    _escape_cell(details),
                )
            )
            + " |"
        )
    printed_any_table = True

if not printed_any_table:
    print("No ground-truth platform comparisons were available for file-level tables.")
PY
}

render_html_report() {
  local report_path="$1"
  local html_output_path="$OUTPUT_DIR/parity_report.html"
  local renderer_log="$LOG_DIR/render_html_report.log"
  local rendered_path=""

  if $VERBOSE; then
    rendered_path="$(
      python3 "$ML_DIR/tools/render_parity_html_report.py" \
        --report "$report_path" \
        --output "$html_output_path"
    )"
  else
    if ! rendered_path="$(
      python3 "$ML_DIR/tools/render_parity_html_report.py" \
        --report "$report_path" \
        --output "$html_output_path" \
        2>"$renderer_log"
    )"; then
      echo "Failed to render HTML parity report at $html_output_path. Log: $renderer_log"
      return 1
    fi
  fi

  LAST_HTML_REPORT="${rendered_path##*$'\n'}"
  if [[ -z "$LAST_HTML_REPORT" ]]; then
    LAST_HTML_REPORT="$html_output_path"
  fi
  return 0
}

render_compact_summary() {
  local report_path="$1"
  shift
  python3 - "$report_path" "$@" <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
selected_platforms = sys.argv[2:]

if not report_path.exists():
    print("File-level summary unavailable: comparison report not found.")
    raise SystemExit(0)

payload = json.loads(report_path.read_text())
ground_truth_platform = str(payload.get("ground_truth_platform", "python"))
comparisons = payload.get("comparisons", [])
if not isinstance(comparisons, list):
    comparisons = []

summary_by_platform: dict[str, tuple[int, int, int]] = {}
for comparison in comparisons:
    if not isinstance(comparison, dict):
        continue
    if str(comparison.get("reference_platform", "")) != ground_truth_platform:
        continue

    candidate_platform = str(comparison.get("candidate_platform", "unknown"))
    file_summary = comparison.get("file_summary") or {}
    if not isinstance(file_summary, dict):
        file_summary = {}
    pass_count = int(file_summary.get("pass_count", len(comparison.get("passing_files", []))))
    fail_count = int(file_summary.get("fail_count", len(comparison.get("failing_files", []))))
    total_files = int(file_summary.get("total_reference_files", comparison.get("total_reference_files", 0)))
    summary_by_platform[candidate_platform] = (pass_count, fail_count, total_files)

print(f"File-level summary (vs {ground_truth_platform}):")
for platform in selected_platforms:
    if platform == ground_truth_platform:
        continue
    if platform in summary_by_platform:
        pass_count, fail_count, total_files = summary_by_platform[platform]
        print(f"  {platform}: {pass_count} pass / {fail_count} fail / {total_files} total")
    else:
        print(f"  {platform}: unavailable (no platform results)")
PY
}

LAST_HTML_REPORT=""
declare -a failed_platform_runners=()

for platform in "${selected_platforms[@]}"; do
  platform_log="$PLATFORM_LOG_DIR/$platform.log"
  set +e
  if $VERBOSE; then
    run_platform_runner "$platform" 2>&1 | tee "$platform_log"
    platform_run_exit=${PIPESTATUS[0]}
  else
    run_platform_runner "$platform" >"$platform_log" 2>&1
    platform_run_exit=$?
  fi
  set -e

  case "$platform_run_exit" in
    0)
      echo "Platform runner completed for $platform."
      ;;
    1)
      echo "Platform runner failed for $platform. Log: $platform_log"
      failed_platform_runners+=("$platform(exit=1)")
      ;;
    2)
      echo "Platform runner unavailable for $platform. Log: $platform_log"
      ;;
    *)
      echo "Platform runner returned unexpected exit code $platform_run_exit for $platform. Log: $platform_log"
      failed_platform_runners+=("$platform(exit=$platform_run_exit)")
      ;;
  esac
done

if ((${#failed_platform_runners[@]} > 0)); then
  echo "One or more platform runners failed: ${failed_platform_runners[*]}" >&2
  if $FAIL_ON_PLATFORM_RUNNER_ERROR; then
    echo "Failing because --fail-on-platform-runner-error is set" >&2
    exit 1
  fi
  echo "Continuing with available platform outputs."
fi

declare -a compare_args=()
missing_platform_count=0

for platform in "${selected_platforms[@]}"; do
  platform_output="$OUTPUT_DIR/$platform/results.json"
  if [[ -f "$platform_output" ]]; then
    compare_args+=(--platform-result "$platform=$platform_output")
    if $VERBOSE; then
      echo "Using $platform output: $platform_output"
    fi
  else
    if $VERBOSE; then
      echo "Platform output unavailable for $platform at $platform_output"
    fi
    missing_platform_count=$((missing_platform_count + 1))
  fi
done

if $FAIL_ON_MISSING_PLATFORM && ((missing_platform_count > 0)); then
  echo "Missing platform outputs and --fail-on-missing-platform is set" >&2
  exit 1
fi

if ((${#compare_args[@]} == 0)); then
  if $ALLOW_EMPTY_COMPARISON; then
    echo "No platform outputs available; continuing because --allow-empty-comparison is set"
  else
    echo "No platform outputs available for comparison. Provide at least one platform result or use --allow-empty-comparison." >&2
    exit 1
  fi
fi

compare_output="$OUTPUT_DIR/comparison_report.json"
compare_log="$LOG_DIR/comparison.log"
compare_cmd=(
  uv run --project "$UV_PROJECT_DIR" --no-sync python "$ML_DIR/tools/compare_parity_outputs.py"
  --ground-truth "$PYTHON_OUTPUT_DIR/results.json"
  --no-pairwise
  --output "$compare_output"
)
if ((${#compare_args[@]} > 0)); then
  compare_cmd+=("${compare_args[@]}")
fi

set +e
if $VERBOSE; then
  "${compare_cmd[@]}" 2>&1 | tee "$compare_log"
  compare_exit=${PIPESTATUS[0]}
else
  "${compare_cmd[@]}" >"$compare_log" 2>&1
  compare_exit=$?
fi
set -e

echo "Comparison report: $compare_output"
if [[ -f "$compare_output" ]]; then
  if $VERBOSE; then
    render_file_level_report_tables "$compare_output"
  fi
  if ! render_html_report "$compare_output"; then
    echo "Continuing without HTML report due to renderer failure."
  fi
  render_compact_summary "$compare_output" "${selected_platforms[@]}"
  if [[ -n "$LAST_HTML_REPORT" ]]; then
    echo "HTML parity report: $LAST_HTML_REPORT"
    echo "HTML parity report URL: file://$LAST_HTML_REPORT"
  fi
fi

if ((compare_exit != 0)); then
  echo "Parity comparison command failed. Log: $compare_log"
  exit "$compare_exit"
fi

echo "Detailed logs: $LOG_DIR"
echo "Parity comparison completed"
if $UPDATE_GOLDEN; then
  echo "--update-golden currently regenerates Python ONNX ground-truth outputs only."
fi
