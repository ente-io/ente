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

PLATFORMS="all"
FAIL_ON_MISSING_PLATFORM=false
FAIL_ON_PLATFORM_RUNNER_ERROR=false
ALLOW_EMPTY_COMPARISON=false
STRICT=false
CONTINUE_ON_MISSING_DEVICES=true
REQUIRE_COMPARISON_PASS=false
OUTPUT_DIR="$ROOT_DIR/infra/ml/test/out/parity"
VERBOSE=false

usage() {
  cat <<EOF
Usage: infra/ml/test/tools/run_suite.sh [flags]

Flags:
  --platforms all|desktop|android|ios   (default: all)
  --strict                              (optional future mode; enforces full pass and complete platform coverage)
  --continue-on-missing-devices         (default: enabled, except in --strict mode; continue when android/ios devices are unavailable)
  --fail-on-missing-platform            (default: disabled)
  --fail-on-platform-runner-error       (default: disabled)
  --allow-empty-comparison              (default: disabled)
  --output-dir <path>                   (default: infra/ml/test/out/parity)
  --verbose                             (default: disabled)
EOF
}

while (($# > 0)); do
  case "$1" in
    --platforms)
      PLATFORMS="$2"
      shift 2
      ;;
    --strict)
      STRICT=true
      shift
      ;;
    --continue-on-missing-devices)
      CONTINUE_ON_MISSING_DEVICES=true
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

if $STRICT; then
  CONTINUE_ON_MISSING_DEVICES=false
  FAIL_ON_MISSING_PLATFORM=true
  FAIL_ON_PLATFORM_RUNNER_ERROR=true
  REQUIRE_COMPARISON_PASS=true
fi

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
echo "  platforms: $PLATFORMS"
echo "  output_dir: $OUTPUT_DIR"
echo "  verbose: $VERBOSE"
echo "  strict: $STRICT"
echo "  continue_on_missing_devices: $CONTINUE_ON_MISSING_DEVICES"
echo "  fail_on_missing_platform: $FAIL_ON_MISSING_PLATFORM"
echo "  fail_on_platform_runner_error: $FAIL_ON_PLATFORM_RUNNER_ERROR"
echo "  allow_empty_comparison: $ALLOW_EMPTY_COMPARISON"

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

sha256_file() {
  python3 - "$1" <<'PY'
import hashlib
import sys

path = sys.argv[1]
digest = hashlib.sha256()
with open(path, "rb") as file:
    for chunk in iter(lambda: file.read(1024 * 1024), b""):
        digest.update(chunk)
print(digest.hexdigest())
PY
}

cache_key_for_url() {
  python3 - "$1" <<'PY'
import hashlib
import sys

print(hashlib.sha256(sys.argv[1].encode("utf-8")).hexdigest())
PY
}

preflight_platform_device_available() {
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

preflight_platform_device_id_available() {
  local platform="$1"
  local device_id="$2"
  python3 - "$platform" "$device_id" <<'PY'
from __future__ import annotations

import json
import subprocess
import sys

platform = sys.argv[1]
device_id = sys.argv[2]

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

def is_platform_match(device: dict[str, object]) -> bool:
    target = str(device.get("targetPlatform", "")).lower()
    name = str(device.get("name", "")).lower()
    if platform == "android":
        return "android" in target or "android" in name
    if platform == "ios":
        return "ios" in target or "iphone" in name or "ipad" in name
    return False

for device in devices:
    if str(device.get("id", "")) == device_id and is_platform_match(device):
        sys.exit(0)
sys.exit(1)
PY
}

resolve_android_tool_path() {
  local binary_name="$1"
  local relative_path="$2"
  local sdk_root=""
  local candidate=""

  if command -v "$binary_name" >/dev/null 2>&1; then
    command -v "$binary_name"
    return 0
  fi

  for sdk_root in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}" "$HOME/Library/Android/sdk"; do
    if [[ -z "$sdk_root" ]]; then
      continue
    fi

    candidate="$sdk_root/$relative_path"
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

pick_ios_simulator_udid() {
  local preferred_udid="${1:-}"
  python3 - "$preferred_udid" <<'PY'
from __future__ import annotations

import json
import subprocess
import sys

preferred_udid = sys.argv[1]

try:
    raw = subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "available", "--json"],
        stderr=subprocess.STDOUT,
        text=True,
    )
    payload = json.loads(raw)
except Exception:
    sys.exit(2)

devices_by_runtime = payload.get("devices", {})
candidates: list[tuple[tuple[object, ...], str]] = []

for runtime, devices in devices_by_runtime.items():
    runtime_lower = str(runtime).lower()
    if "ios" not in runtime_lower:
        continue
    if any(blocked in runtime_lower for blocked in ("tvos", "watchos", "visionos")):
        continue

    for device in devices:
        if not bool(device.get("isAvailable", True)):
            continue

        udid = str(device.get("udid", "")).strip()
        if not udid:
            continue

        name = str(device.get("name", "")).strip()
        state = str(device.get("state", "")).strip().lower()

        score = (
            0 if state == "booted" else 1,
            0 if "iphone" in name.lower() else 1,
            name.lower(),
            udid.lower(),
        )
        candidates.append((score, udid))

if preferred_udid:
    for _, udid in candidates:
        if udid == preferred_udid:
            print(udid)
            sys.exit(0)

if not candidates:
    sys.exit(1)

candidates.sort(key=lambda entry: entry[0])
print(candidates[0][1])
PY
}

wait_for_ios_simulator_boot() {
  local udid="$1"
  local timeout_seconds="${2:-180}"
  python3 - "$udid" "$timeout_seconds" <<'PY'
from __future__ import annotations

import json
import subprocess
import sys
import time

udid = sys.argv[1]
timeout_seconds = float(sys.argv[2])
deadline = time.time() + timeout_seconds

while time.time() < deadline:
    try:
        raw = subprocess.check_output(
            ["xcrun", "simctl", "list", "devices", "--json"],
            stderr=subprocess.STDOUT,
            text=True,
        )
        payload = json.loads(raw)
    except Exception:
        time.sleep(2.0)
        continue

    for devices in payload.get("devices", {}).values():
        for device in devices:
            if str(device.get("udid", "")).strip() != udid:
                continue
            state = str(device.get("state", "")).strip().lower()
            if state == "booted":
                sys.exit(0)
            break
    time.sleep(2.0)

sys.exit(1)
PY
}

ensure_ios_simulator_running() {
  local explicit_device_id="${ML_PARITY_IOS_DEVICE_ID:-}"
  local preferred_udid="$explicit_device_id"
  local selected_udid=""

  if [[ -n "$explicit_device_id" ]]; then
    if preflight_platform_device_id_available "ios" "$explicit_device_id"; then
      return 0
    fi
  elif preflight_platform_device_available "ios"; then
    return 0
  fi

  if ! command -v xcrun >/dev/null 2>&1; then
    echo "iOS auto-boot skipped: xcrun is unavailable."
    return 1
  fi

  if ! selected_udid="$(pick_ios_simulator_udid "$preferred_udid")"; then
    echo "iOS auto-boot skipped: no available iOS simulator could be selected."
    return 1
  fi

  if [[ -z "$selected_udid" ]]; then
    echo "iOS auto-boot skipped: simulator selection returned an empty UDID."
    return 1
  fi

  if [[ -n "$explicit_device_id" && "$explicit_device_id" != "$selected_udid" ]]; then
    echo "Configured iOS device '$explicit_device_id' is unavailable; using simulator '$selected_udid' instead."
  fi

  echo "Auto-booting iOS simulator: $selected_udid"
  set +e
  xcrun simctl boot "$selected_udid" >/dev/null 2>&1
  local boot_exit=$?
  set -e
  if ((boot_exit != 0)); then
    local simulator_line=""
    simulator_line="$(xcrun simctl list devices "$selected_udid" 2>/dev/null | tr -d '\r' || true)"
    if ! printf '%s\n' "$simulator_line" | grep -q "Booted"; then
      echo "iOS auto-boot failed for simulator '$selected_udid'."
      return 1
    fi
  fi

  if ! wait_for_ios_simulator_boot "$selected_udid" "${ML_PARITY_IOS_BOOT_TIMEOUT_SECONDS:-180}"; then
    echo "iOS simulator '$selected_udid' did not reach Booted state in time."
    return 1
  fi

  export ML_PARITY_IOS_DEVICE_ID="$selected_udid"
  echo "iOS simulator ready: $selected_udid"
  return 0
}

pick_android_avd_name() {
  local emulator_bin="$1"
  local preferred_avd="${ML_PARITY_ANDROID_AVD:-}"
  local listed_avds=""

  listed_avds="$("$emulator_bin" -list-avds 2>/dev/null || true)"
  if [[ -z "$listed_avds" ]]; then
    return 1
  fi

  if [[ -n "$preferred_avd" ]]; then
    if printf '%s\n' "$listed_avds" | grep -Fxq "$preferred_avd"; then
      echo "$preferred_avd"
      return 0
    fi
    echo "Configured Android AVD '$preferred_avd' was not found; selecting the first available AVD."
  fi

  printf '%s\n' "$listed_avds" | awk 'NF {print; exit}'
  return 0
}

list_android_emulator_serials() {
  local adb_bin="$1"
  python3 - "$adb_bin" <<'PY'
from __future__ import annotations

import re
import subprocess
import sys

adb_bin = sys.argv[1]
emulator_line = re.compile(r"^(emulator-\d+)\s+\S+$")

try:
    output = subprocess.check_output(
        [adb_bin, "devices"],
        stderr=subprocess.STDOUT,
        text=True,
    )
except Exception:
    sys.exit(0)

for line in output.splitlines()[1:]:
    match = emulator_line.match(line.strip())
    if match:
        print(match.group(1))
PY
}

wait_for_android_emulator_boot() {
  local adb_bin="$1"
  local timeout_seconds="${2:-300}"
  local existing_serials_csv="${3:-}"
  python3 - "$adb_bin" "$timeout_seconds" "$existing_serials_csv" <<'PY'
from __future__ import annotations

import re
import subprocess
import sys
import time

adb_bin = sys.argv[1]
timeout_seconds = float(sys.argv[2])
existing_serials = {value for value in sys.argv[3].split(",") if value}
deadline = time.time() + timeout_seconds
emulator_line = re.compile(r"^(emulator-\d+)\s+device$")

while time.time() < deadline:
    try:
        output = subprocess.check_output(
            [adb_bin, "devices"],
            stderr=subprocess.STDOUT,
            text=True,
        )
    except Exception:
        time.sleep(2.0)
        continue

    serials: list[str] = []
    for line in output.splitlines()[1:]:
        match = emulator_line.match(line.strip())
        if match:
            serials.append(match.group(1))

    for serial in serials:
        if serial in existing_serials:
            continue

        try:
            boot_completed = (
                subprocess.check_output(
                    [adb_bin, "-s", serial, "shell", "getprop", "sys.boot_completed"],
                    stderr=subprocess.DEVNULL,
                    text=True,
                    timeout=5,
                )
                .strip()
                .replace("\r", "")
            )
        except Exception:
            continue

        if boot_completed == "1":
            print(serial)
            sys.exit(0)

    time.sleep(2.0)

sys.exit(1)
PY
}

ensure_android_emulator_running() {
  local explicit_device_id="${ML_PARITY_ANDROID_DEVICE_ID:-}"
  local emulator_bin=""
  local adb_bin=""
  local avd_name=""
  local booted_serial=""
  local existing_emulator_serials_csv=""
  local emulator_log="${PLATFORM_LOG_DIR:-$LOG_DIR/platforms}/android_emulator_boot.log"

  if [[ -n "$explicit_device_id" ]]; then
    if preflight_platform_device_id_available "android" "$explicit_device_id"; then
      return 0
    fi
  elif preflight_platform_device_available "android"; then
    return 0
  fi

  if ! emulator_bin="$(resolve_android_tool_path "emulator" "emulator/emulator")"; then
    echo "Android auto-boot skipped: emulator tool is unavailable."
    return 1
  fi

  if ! adb_bin="$(resolve_android_tool_path "adb" "platform-tools/adb")"; then
    echo "Android auto-boot skipped: adb tool is unavailable."
    return 1
  fi

  if ! avd_name="$(pick_android_avd_name "$emulator_bin")"; then
    echo "Android auto-boot skipped: no AVDs are available."
    return 1
  fi

  "$adb_bin" start-server >/dev/null 2>&1 || true
  existing_emulator_serials_csv="$(
    list_android_emulator_serials "$adb_bin" | tr '\n' ',' | sed 's/,$//'
  )"

  echo "Auto-booting Android emulator: $avd_name"
  nohup "$emulator_bin" -avd "$avd_name" -no-snapshot-save -no-boot-anim >"$emulator_log" 2>&1 &

  if ! booted_serial="$(
    wait_for_android_emulator_boot \
      "$adb_bin" \
      "${ML_PARITY_ANDROID_BOOT_TIMEOUT_SECONDS:-300}" \
      "$existing_emulator_serials_csv"
  )"; then
    echo "Android emulator '$avd_name' did not report boot completion in time. Boot log: $emulator_log"
    return 1
  fi

  if [[ -n "$explicit_device_id" && "$explicit_device_id" != "$booted_serial" ]]; then
    echo "Configured Android device '$explicit_device_id' is unavailable; using emulator '$booted_serial' instead."
  fi

  export ML_PARITY_ANDROID_DEVICE_ID="$booted_serial"
  echo "Android emulator ready: $booted_serial"
  return 0
}

ensure_selected_mobile_devices_running() {
  local -a auto_boot_failures=()

  for platform in "${selected_platforms[@]}"; do
    case "$platform" in
      android)
        if ! ensure_android_emulator_running; then
          auto_boot_failures+=("android")
        fi
        ;;
      ios)
        if ! ensure_ios_simulator_running; then
          auto_boot_failures+=("ios")
        fi
        ;;
    esac
  done

  if ((${#auto_boot_failures[@]} > 0)); then
    echo "Auto-boot did not guarantee device availability for: ${auto_boot_failures[*]}"
    echo "Proceeding to preflight checks with configured strictness."
  fi
}

run_preflight_checks() {
  local desktop_dir="$ROOT_DIR/desktop"
  local web_dir="$ROOT_DIR/web"
  local runner_path="$desktop_dir/scripts/ml_parity_runner.ts"
  local mobile_dir="$ROOT_DIR/mobile/apps/photos"
  local driver_path="$mobile_dir/test_driver/ml_parity_driver.dart"
  local -a preflight_errors=()
  local -a preflight_warnings=()

  for platform in "${selected_platforms[@]}"; do
    case "$platform" in
      desktop)
        if [[ ! -f "$runner_path" ]]; then
          preflight_errors+=("desktop parity runner not found at $runner_path")
        fi
        if [[ ! -d "$desktop_dir/node_modules" ]]; then
          preflight_errors+=("desktop dependencies missing: $desktop_dir/node_modules")
        fi
        if [[ ! -d "$web_dir/node_modules" ]]; then
          preflight_errors+=("web dependencies missing: $web_dir/node_modules")
        fi
        if ! command -v npx >/dev/null 2>&1; then
          preflight_errors+=("npx is required for desktop parity")
        fi
        if ! command -v yarn >/dev/null 2>&1; then
          preflight_errors+=("yarn is required for desktop parity compilation")
        fi
        ;;
      android|ios)
        if ! command -v flutter >/dev/null 2>&1; then
          preflight_errors+=("flutter is required for $platform parity")
          continue
        fi
        if [[ ! -f "$driver_path" ]]; then
          preflight_errors+=("mobile parity driver not found at $driver_path")
        fi

        local target_path=""
        local explicit_device_id=""
        if [[ "$platform" == "android" ]]; then
          target_path="$mobile_dir/integration_test/ml_parity_android_test.dart"
          explicit_device_id="${ML_PARITY_ANDROID_DEVICE_ID:-}"
        else
          target_path="$mobile_dir/integration_test/ml_parity_ios_test.dart"
          explicit_device_id="${ML_PARITY_IOS_DEVICE_ID:-}"
        fi
        if [[ ! -f "$target_path" ]]; then
          preflight_errors+=("$platform parity test target not found at $target_path")
        fi

        local device_available_exit=0
        if [[ -n "$explicit_device_id" ]]; then
          if preflight_platform_device_id_available "$platform" "$explicit_device_id"; then
            device_available_exit=0
          else
            device_available_exit=$?
          fi
          case "$device_available_exit" in
            0)
              ;;
            1)
              if $CONTINUE_ON_MISSING_DEVICES; then
                preflight_warnings+=(
                  "$platform device id '$explicit_device_id' is unavailable; continuing due to --continue-on-missing-devices"
                )
              else
                preflight_errors+=(
                  "$platform device id '$explicit_device_id' is unavailable (set --continue-on-missing-devices to continue anyway)"
                )
              fi
              ;;
            *)
              if $CONTINUE_ON_MISSING_DEVICES; then
                preflight_warnings+=(
                  "could not verify $platform device id '$explicit_device_id'; continuing due to --continue-on-missing-devices"
                )
              else
                preflight_errors+=(
                  "could not verify $platform device id '$explicit_device_id' (set --continue-on-missing-devices to continue anyway)"
                )
              fi
              ;;
          esac
        else
          if preflight_platform_device_available "$platform"; then
            device_available_exit=0
          else
            device_available_exit=$?
          fi

          case "$device_available_exit" in
            0)
              ;;
            1)
              if $CONTINUE_ON_MISSING_DEVICES; then
                preflight_warnings+=(
                  "no connected $platform device/simulator detected; continuing due to --continue-on-missing-devices"
                )
              else
                preflight_errors+=(
                  "no connected $platform device/simulator detected (set --continue-on-missing-devices to continue anyway)"
                )
              fi
              ;;
            *)
              if $CONTINUE_ON_MISSING_DEVICES; then
                preflight_warnings+=(
                  "could not determine $platform device availability; continuing due to --continue-on-missing-devices"
                )
              else
                preflight_errors+=(
                  "could not determine $platform device availability (set --continue-on-missing-devices to continue anyway)"
                )
              fi
              ;;
          esac
        fi
        ;;
    esac
  done

  if ((${#preflight_warnings[@]} > 0)); then
    echo "Preflight warnings:"
    for warning in "${preflight_warnings[@]}"; do
      echo "  - $warning"
    done
  fi

  if ((${#preflight_errors[@]} > 0)); then
    echo "Preflight failed:" >&2
    for error in "${preflight_errors[@]}"; do
      echo "  - $error" >&2
    done
    exit 1
  fi

  echo "Preflight checks passed"
}

echo "Ensuring selected mobile simulators/emulators are running"
ensure_selected_mobile_devices_running

echo "Running preflight checks"
run_preflight_checks

echo "Syncing local fixture directory (cached): $TEST_DATA_DIR"
mkdir -p "$TEST_DATA_DIR"
fixture_metadata_dir="$TEST_DATA_DIR/.source-metadata"
mkdir -p "$fixture_metadata_dir"

downloaded_count=0
reused_count=0
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

  cache_key="$(cache_key_for_url "$source_url")"
  etag_path="$fixture_metadata_dir/$cache_key.etag"

  should_download=false
  reason=""

  if [[ ! -f "$target_path" ]]; then
    should_download=true
    reason="missing local fixture"
  fi

  if [[ -f "$target_path" && -n "$source_sha" ]]; then
    actual_sha="$(sha256_file "$target_path")"
    if [[ "$actual_sha" != "$source_sha" ]]; then
      should_download=true
      reason="local SHA-256 mismatch"
    fi
  fi

  remote_headers=""
  if remote_headers="$(curl -fsSI --retry 3 --retry-delay 1 "$source_url" 2>/dev/null)"; then
    remote_etag="$(
      printf '%s\n' "$remote_headers" | awk -F': ' 'tolower($1)=="etag"{print $2; exit}' | tr -d '\r'
    )"

    if [[ -n "$remote_etag" ]]; then
      local_etag=""
      if [[ -f "$etag_path" ]]; then
        local_etag="$(tr -d '\r\n' <"$etag_path")"
      fi
      if [[ "$local_etag" != "$remote_etag" ]]; then
        should_download=true
        if [[ -z "$reason" ]]; then
          reason="remote ETag changed"
        fi
      fi
    elif [[ -f "$target_path" ]]; then
      should_download=true
      if [[ -z "$reason" ]]; then
        reason="remote ETag unavailable"
      fi
    fi
  else
    if [[ -f "$target_path" ]]; then
      should_download=true
      if [[ -z "$reason" ]]; then
        reason="failed to fetch remote metadata"
      fi
    fi
    remote_etag=""
  fi

  if $should_download; then
    tmp_path="$target_path.tmp"
    if ! curl -fsSL --retry 3 --retry-delay 1 "$source_url" -o "$tmp_path"; then
      rm -f "$tmp_path"
      echo "Failed to download fixture from $source_url" >&2
      exit 1
    fi

    if [[ -n "$source_sha" ]]; then
      actual_sha="$(sha256_file "$tmp_path")"
      if [[ "$actual_sha" != "$source_sha" ]]; then
        rm -f "$tmp_path"
        echo "SHA-256 mismatch for $source_rel: expected $source_sha got $actual_sha" >&2
        exit 1
      fi
    fi

    mv "$tmp_path" "$target_path"
    downloaded_count=$((downloaded_count + 1))
    if [[ -n "$remote_etag" ]]; then
      printf '%s\n' "$remote_etag" >"$etag_path"
    else
      rm -f "$etag_path"
    fi

    if $VERBOSE; then
      echo "Downloaded fixture: $source_rel ($reason)"
    fi
  else
    reused_count=$((reused_count + 1))
    if $VERBOSE; then
      echo "Reused cached fixture: $source_rel"
    fi
  fi
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
echo "Fixture sync summary: downloaded=$downloaded_count reused=$reused_count"

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

  if [[ -n "$device_id" ]]; then
    local configured_device_exit=0
    if preflight_platform_device_id_available "$platform" "$device_id"; then
      configured_device_exit=0
    else
      configured_device_exit=$?
    fi
    case "$configured_device_exit" in
      0)
        ;;
      1)
        echo "Configured $platform device id '$device_id' is unavailable; skipping $platform run."
        return 2
        ;;
      *)
        echo "Could not verify configured $platform device id '$device_id'; skipping $platform run."
        return 2
        ;;
    esac
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

render_markdown_report() {
  local report_path="$1"
  local markdown_output_path="$OUTPUT_DIR/parity_report.llm.md"
  local renderer_log="$LOG_DIR/render_markdown_report.log"
  local rendered_path=""

  if $VERBOSE; then
    if ! rendered_path="$(
      python3 "$ML_DIR/tools/render_parity_markdown_report.py" \
        --report "$report_path" \
        --output "$markdown_output_path"
    )"; then
      echo "Failed to render Markdown parity report at $markdown_output_path."
      return 1
    fi
  else
    if ! rendered_path="$(
      python3 "$ML_DIR/tools/render_parity_markdown_report.py" \
        --report "$report_path" \
        --output "$markdown_output_path" \
        2>"$renderer_log"
    )"; then
      echo "Failed to render Markdown parity report at $markdown_output_path. Log: $renderer_log"
      return 1
    fi
  fi

  LAST_MARKDOWN_REPORT="${rendered_path##*$'\n'}"
  if [[ -z "$LAST_MARKDOWN_REPORT" ]]; then
    LAST_MARKDOWN_REPORT="$markdown_output_path"
  fi
  if [[ ! -f "$LAST_MARKDOWN_REPORT" ]]; then
    echo "Markdown parity report was not generated at $LAST_MARKDOWN_REPORT."
    return 1
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

comparison_report_passed() {
  local report_path="$1"
  python3 - "$report_path" <<'PY'
import json
import sys
from pathlib import Path

report_path = Path(sys.argv[1])
if not report_path.exists():
    sys.exit(2)

payload = json.loads(report_path.read_text())
sys.exit(0 if bool(payload.get("passed", False)) else 1)
PY
}

LAST_HTML_REPORT=""
LAST_MARKDOWN_REPORT=""
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
  if ! render_markdown_report "$compare_output"; then
    echo "Continuing without Markdown report due to renderer failure."
  fi
  render_compact_summary "$compare_output" "${selected_platforms[@]}"
  if [[ -n "$LAST_HTML_REPORT" ]]; then
    echo "HTML parity report: $LAST_HTML_REPORT"
    echo "HTML parity report URL: file://$LAST_HTML_REPORT"
  fi
  if [[ -n "$LAST_MARKDOWN_REPORT" ]]; then
    echo "Markdown parity report (LLM): $LAST_MARKDOWN_REPORT"
    echo "Agent note: for extensive results beyond the printed summary, read $LAST_MARKDOWN_REPORT."
  fi
fi

if ((compare_exit != 0)); then
  echo "Parity comparison command failed. Log: $compare_log"
  exit "$compare_exit"
fi

if $REQUIRE_COMPARISON_PASS; then
  if comparison_report_passed "$compare_output"; then
    echo "Strict mode: comparison report passed."
  else
    comparison_pass_exit=$?
    if ((comparison_pass_exit == 2)); then
      echo "Strict mode failed: comparison report is missing at $compare_output" >&2
    else
      echo "Strict mode failed: comparison report contains parity failures." >&2
    fi
    exit 1
  fi
fi

echo "Detailed logs: $LOG_DIR"
echo "Parity comparison completed"
