#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
MODE="debug"
SERIAL=""
SKIP_BUILD=0
SKIP_RUST=0
ENDPOINT=""

usage() {
  cat <<'EOF'
Build + install + launch Ensu Android app.

Usage:
  ./run.sh [debug|release] [options]

Options:
  --device <serial>    Target adb device serial
  --skip-build         Skip build step
  --skip-rust          Pass through to build step
  --endpoint <url>     Set ENTE_API_ENDPOINT for this run/build
  -h, --help           Show help

Examples:
  ./run.sh
  ./run.sh --device emulator-5554
  ./run.sh release --skip-rust
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    debug|release)
      MODE="$1"
      shift
      ;;
    --device)
      SERIAL="${2:-}"
      if [[ -z "$SERIAL" ]]; then
        echo "Missing value for --device" >&2
        exit 1
      fi
      shift 2
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    --skip-rust)
      SKIP_RUST=1
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

if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found in PATH" >&2
  exit 1
fi

ADB_CMD=(adb)
if [[ -n "$SERIAL" ]]; then
  ADB_CMD+=( -s "$SERIAL" )
fi

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  BUILD_ARGS=("$MODE")
  if [[ "$SKIP_RUST" -eq 1 ]]; then
    BUILD_ARGS+=("--skip-rust")
  fi
  if [[ -n "$ENDPOINT" ]]; then
    BUILD_ARGS+=("--endpoint" "$ENDPOINT")
  fi
  "$ROOT/build.sh" "${BUILD_ARGS[@]}"
fi

if [[ "$MODE" == "release" ]]; then
  APK_PATH="$ROOT/app-ui/build/outputs/apk/release/app-ui-release.apk"
else
  APK_PATH="$ROOT/app-ui/build/outputs/apk/debug/app-ui-debug.apk"
fi

if [[ ! -f "$APK_PATH" ]]; then
  echo "APK not found: $APK_PATH" >&2
  exit 1
fi

echo "==> Installing $APK_PATH"
"${ADB_CMD[@]}" install -r "$APK_PATH"

echo "==> Launching io.ente.ensu"
"${ADB_CMD[@]}" shell monkey -p io.ente.ensu -c android.intent.category.LAUNCHER 1 >/dev/null

echo "✅ Ensu launched on Android"
