#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
RUST_BUILD_SCRIPT="$ROOT/../../packages/rust/tool/build_android.sh"

MODE="debug"
SKIP_RUST=0
SKIP_APP=0
ENDPOINT=""

usage() {
  cat <<'EOF'
Build Ensu Android app.

Usage:
  ./build.sh [debug|release] [options]

Options:
  --skip-rust          Skip Rust/jni build step
  --skip-app           Skip Gradle app build step
  --endpoint <url>     Set ENTE_API_ENDPOINT for this build
  -h, --help           Show help

Examples:
  ./build.sh
  ./build.sh release
  ./build.sh debug --endpoint https://api.example.com
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    debug|release)
      MODE="$1"
      shift
      ;;
    --skip-rust)
      SKIP_RUST=1
      shift
      ;;
    --skip-app)
      SKIP_APP=1
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

if [[ -n "$ENDPOINT" ]]; then
  export ENTE_API_ENDPOINT="$ENDPOINT"
fi

if [[ "$SKIP_RUST" -eq 0 ]]; then
  echo "==> Building Rust Android artifacts"
  "$RUST_BUILD_SCRIPT"
fi

if [[ "$SKIP_APP" -eq 0 ]]; then
  cd "$ROOT"

  if [[ "$MODE" == "release" ]]; then
    TASK=":app-ui:assembleRelease"
    APK_PATH="app-ui/build/outputs/apk/release/app-ui-release.apk"
  else
    TASK=":app-ui:assembleDebug"
    APK_PATH="app-ui/build/outputs/apk/debug/app-ui-debug.apk"
  fi

  echo "==> Running Gradle task $TASK"
  ./gradlew "$TASK"
  echo "✅ APK: $ROOT/$APK_PATH"
fi
