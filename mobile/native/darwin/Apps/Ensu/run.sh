#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE_ID="io.ente.ensu"

DESTINATION_ID=""
SKIP_BUILD=0
ENDPOINT=""

usage() {
  cat <<'EOF'
Build + install + launch Ensu on iOS Simulator.

Usage:
  ./run.sh [options]

Options:
  --destination-id <id>  Use specific simulator id
  --skip-build           Skip build step
  --endpoint <url>       Set ENTE_API_ENDPOINT for build
  -h, --help             Show help

Examples:
  ./run.sh                          # prefers currently booted iPhone simulator
  ./run.sh --destination-id <SIMULATOR_UUID>
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

pick_simulator_id() {
  local destinations

  destinations="$(xcodebuild -scheme Ensu -showdestinations 2>/dev/null \
    | sed -n 's/.*platform:iOS Simulator,.*id:\([^,}]*\).*, name:\([^}]*\).*/\1|\2/p' \
    | grep -v '^dvtdevice-' || true)"

  if [[ -z "$destinations" ]]; then
    return
  fi

  local iphone_id
  iphone_id="$(printf "%s\n" "$destinations" | awk -F'|' '/iPhone/ { print $1; exit }')"
  if [[ -n "$iphone_id" ]]; then
    echo "$iphone_id"
    return
  fi

  printf "%s\n" "$destinations" | head -n 1 | cut -d'|' -f1
}

app_path_for_destination() {
  xcodebuild \
    -scheme Ensu \
    -configuration Debug \
    -sdk iphonesimulator \
    -destination "id=$DESTINATION_ID" \
    -showBuildSettings 2>/dev/null \
    | awk '
      /^Build settings for action build and target Ensu:/ { in_target=1; next }
      /^Build settings for action build and target / { in_target=0 }
      in_target && $1 == "TARGET_BUILD_DIR" { build_dir=$3 }
      in_target && $1 == "WRAPPER_NAME" { wrapper_name=$3 }
      END {
        if (build_dir != "" && wrapper_name != "") {
          print build_dir "/" wrapper_name
        }
      }
    '
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --destination-id)
      DESTINATION_ID="${2:-}"
      if [[ -z "$DESTINATION_ID" ]]; then
        echo "Missing value for --destination-id" >&2
        exit 1
      fi
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    --endpoint)
      ENDPOINT="${2:-}"
      if [[ -z "$ENDPOINT" ]]; then
        echo "Missing value for --endpoint" >&2
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

if [[ -z "$DESTINATION_ID" ]]; then
  DESTINATION_ID="$(pick_booted_simulator_id)"
fi
if [[ -z "$DESTINATION_ID" ]]; then
  DESTINATION_ID="$(pick_simulator_id)"
fi
if [[ -z "$DESTINATION_ID" ]]; then
  echo "No iOS Simulator destination found. Open Simulator.app once and retry." >&2
  exit 1
fi

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  BUILD_ARGS=(sim --destination-id "$DESTINATION_ID")
  if [[ -n "$ENDPOINT" ]]; then
    BUILD_ARGS+=(--endpoint "$ENDPOINT")
  fi
  "$ROOT/build.sh" "${BUILD_ARGS[@]}"
fi

APP_PATH="$(app_path_for_destination)"
if [[ -z "$APP_PATH" ]]; then
  echo "Could not determine built app path from Xcode build settings." >&2
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "App not found: $APP_PATH" >&2
  echo "Run ./build.sh sim first." >&2
  exit 1
fi

echo "==> Booting simulator $DESTINATION_ID"
xcrun simctl boot "$DESTINATION_ID" >/dev/null 2>&1 || true

echo "==> Installing app"
xcrun simctl install "$DESTINATION_ID" "$APP_PATH"

echo "==> Launching $APP_BUNDLE_ID"
xcrun simctl launch "$DESTINATION_ID" "$APP_BUNDLE_ID"

echo "✅ Ensu launched on iOS Simulator"
