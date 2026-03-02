#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_BUNDLE_ID="io.ente.ensu"
APP_PATH="$ROOT/build/Build/Products/Debug-iphonesimulator/ensu.app"

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
  ./run.sh
  ./run.sh --destination-id <SIMULATOR_UUID>
EOF
}

pick_simulator_id() {
  xcodebuild -project ensu.xcodeproj -scheme ensu -showdestinations 2>/dev/null \
    | sed -n 's/.*platform:iOS Simulator,.*id:\([^,}]*\).*/\1/p' \
    | grep -v '^dvtdevice-' \
    | head -n 1
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
