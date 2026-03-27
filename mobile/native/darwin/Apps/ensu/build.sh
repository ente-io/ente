#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT="ensu.xcodeproj"
SCHEME="ensu"
DERIVED_DATA_PATH="$ROOT/build"

MODE="sim"
DESTINATION_ID=""
ENDPOINT=""
ARCHIVE_PATH="$DERIVED_DATA_PATH/Archive/ensu.xcarchive"
EXPORT_PATH="$DERIVED_DATA_PATH/Export"
EXPORT_OPTIONS_PLIST="$ROOT/ExportOptions-AppStore.plist"

XCODE_EXTRA_ARGS=()
XCODE_VERSION="$(xcodebuild -version 2>/dev/null | awk '/^Xcode / { print $2; exit }')"
if [[ "$XCODE_VERSION" == 26* ]]; then
  XCODE_EXTRA_ARGS+=(SWIFT_ENABLE_EXPLICIT_MODULES=NO)
fi

# Run xcodebuild, capturing output to a temp log to avoid SIGPIPE with pipefail.
# On failure, prints the last 30 lines of the log for diagnostics.
run_xcodebuild() {
  local log
  log="$(mktemp)"
  if xcodebuild "$@" > "$log" 2>&1; then
    rm -f "$log"
  else
    local rc=$?
    echo "xcodebuild failed (exit $rc). Last 30 lines:" >&2
    tail -30 "$log" >&2
    rm -f "$log"
    exit $rc
  fi
}

usage() {
  cat <<'EOF'
Build Ensu Apple app.

Usage:
  ./build.sh [sim|device|archive|ipa] [options]

Modes:
  sim        Debug build for iOS simulator (default, prefers booted iPhone)
  device     Debug build for connected iOS device
  archive    Release archive (.xcarchive)
  ipa        Build + export IPA using ExportOptions plist

Options:
  --destination-id <id>         Force specific destination id (sim/device)
  --endpoint <url>              Set ENTE_API_ENDPOINT for this build
  --archive-path <path>         Override archive output path
  --export-path <path>          Override IPA export directory (ipa mode)
  --export-options-plist <path> Override export options plist (ipa mode)
  -h, --help                    Show help

Examples:
  ./build.sh
  ./build.sh sim
  ./build.sh device
  ./build.sh archive
  ./build.sh ipa
EOF
}

pick_booted_simulator_id() {
  if ! command -v python3 >/dev/null 2>&1; then
    return
  fi

  python3 - <<'PY' 2>/dev/null
import json
import subprocess
import sys

try:
    out = subprocess.check_output(
        ["xcrun", "simctl", "list", "devices", "booted", "--json"],
        stderr=subprocess.DEVNULL,
        text=True,
    )
except Exception:
    sys.exit(0)

try:
    data = json.loads(out)
except Exception:
    sys.exit(0)

booted = []
for runtime_devices in data.get("devices", {}).values():
    for device in runtime_devices:
        if device.get("state") != "Booted":
            continue
        if device.get("isAvailable") is False:
            continue
        name = device.get("name", "")
        udid = device.get("udid", "")
        if not udid:
            continue
        booted.append((name, udid))

if not booted:
    sys.exit(0)

booted.sort(key=lambda item: (0 if "iphone" in item[0].lower() else 1, item[0]))
print(booted[0][1])
PY
}

pick_destination_id() {
  local platform="$1"
  local prefer_iphone="${2:-0}"
  local destinations

  destinations="$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>/dev/null \
    | sed -n "s/.*platform:${platform},.*id:\([^,}]*\).*, name:\([^}]*\).*/\1|\2/p" \
    | grep -v '^dvtdevice-' || true)"

  if [[ -z "$destinations" ]]; then
    return
  fi

  if [[ "$prefer_iphone" == "1" ]]; then
    local iphone_id
    iphone_id="$(printf "%s\n" "$destinations" | awk -F'|' '/iPhone/ { print $1; exit }')"
    if [[ -n "$iphone_id" ]]; then
      echo "$iphone_id"
      return
    fi
  fi

  printf "%s\n" "$destinations" | head -n 1 | cut -d'|' -f1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    sim|device|archive|ipa)
      MODE="$1"
      shift
      ;;
    --destination-id)
      DESTINATION_ID="${2:-}"
      if [[ -z "$DESTINATION_ID" ]]; then
        echo "Missing value for --destination-id" >&2
        exit 1
      fi
      shift 2
      ;;
    --endpoint)
      ENDPOINT="${2:-}"
      if [[ -z "$ENDPOINT" ]]; then
        echo "Missing value for --endpoint" >&2
        exit 1
      fi
      shift 2
      ;;
    --archive-path)
      ARCHIVE_PATH="${2:-}"
      if [[ -z "$ARCHIVE_PATH" ]]; then
        echo "Missing value for --archive-path" >&2
        exit 1
      fi
      shift 2
      ;;
    --export-path)
      EXPORT_PATH="${2:-}"
      if [[ -z "$EXPORT_PATH" ]]; then
        echo "Missing value for --export-path" >&2
        exit 1
      fi
      shift 2
      ;;
    --export-options-plist)
      EXPORT_OPTIONS_PLIST="${2:-}"
      if [[ -z "$EXPORT_OPTIONS_PLIST" ]]; then
        echo "Missing value for --export-options-plist" >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

cd "$ROOT"

if [[ -n "$ENDPOINT" ]]; then
  export ENTE_API_ENDPOINT="$ENDPOINT"
fi

build_archive() {
  mkdir -p "$(dirname "$ARCHIVE_PATH")"
  echo "==> Building Release archive"
  run_xcodebuild \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Release \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    archive \
    "${XCODE_EXTRA_ARGS[@]}"
  echo "✅ Archive: $ARCHIVE_PATH"
}

case "$MODE" in
  sim)
    if [[ -z "$DESTINATION_ID" ]]; then
      DESTINATION_ID="$(pick_booted_simulator_id)"
    fi
    if [[ -z "$DESTINATION_ID" ]]; then
      DESTINATION_ID="$(pick_destination_id 'iOS Simulator' 1)"
    fi
    if [[ -z "$DESTINATION_ID" ]]; then
      echo "No iOS Simulator destination found. Open Simulator.app once and retry." >&2
      exit 1
    fi

    echo "==> Building Debug for simulator (id=$DESTINATION_ID)"
    run_xcodebuild \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -configuration Debug \
      -sdk iphonesimulator \
      -destination "id=$DESTINATION_ID" \
      -derivedDataPath "$DERIVED_DATA_PATH" \
      "${XCODE_EXTRA_ARGS[@]}"
    ;;
  device)
    if [[ -z "$DESTINATION_ID" ]]; then
      DESTINATION_ID="$(pick_destination_id 'iOS' 1)"
    fi
    if [[ -z "$DESTINATION_ID" ]]; then
      echo "No connected iOS device found. Connect a device or pass --destination-id." >&2
      exit 1
    fi

    echo "==> Building Debug for device (id=$DESTINATION_ID)"
    run_xcodebuild \
      -project "$PROJECT" \
      -scheme "$SCHEME" \
      -configuration Debug \
      -sdk iphoneos \
      -destination "id=$DESTINATION_ID" \
      -derivedDataPath "$DERIVED_DATA_PATH" \
      "${XCODE_EXTRA_ARGS[@]}"
    ;;
  archive)
    build_archive
    ;;
  ipa)
    if [[ ! -f "$EXPORT_OPTIONS_PLIST" ]]; then
      echo "Export options plist not found: $EXPORT_OPTIONS_PLIST" >&2
      exit 1
    fi

    build_archive

    mkdir -p "$EXPORT_PATH"
    echo "==> Exporting IPA"
    run_xcodebuild \
      -exportArchive \
      -archivePath "$ARCHIVE_PATH" \
      -exportPath "$EXPORT_PATH" \
      -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

    IPA_PATH="$(find "$EXPORT_PATH" -maxdepth 1 -type f -name '*.ipa' | head -n 1 || true)"
    if [[ -n "$IPA_PATH" ]]; then
      echo "✅ IPA: $IPA_PATH"
    else
      echo "✅ Exported to: $EXPORT_PATH"
    fi
    ;;
esac

echo "✅ Done"
