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
  ./build.sh [debug|release|release-apk|bundle|release-aab] [options]

Modes:
  debug        Build debug APK
  release      Build release APK
  release-apk  Alias for release
  bundle       Build release Android App Bundle (.aab)
  release-aab  Alias for bundle

Options:
  --skip-rust          Skip Rust/jni build step
  --skip-app           Skip Gradle app build step
  --endpoint <url>     Set ENTE_API_ENDPOINT for this build
  -h, --help           Show help

Examples:
  ./build.sh
  ./build.sh release
  ./build.sh bundle
  ./build.sh debug --endpoint https://api.example.com
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    debug|release|release-apk|bundle|release-aab)
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

  case "$MODE" in
    release|release-apk)
      TASK=":app-ui:assembleRelease"
      OUTPUT_LABEL="APK"
      OUTPUT_PATH="app-ui/build/outputs/apk/release/app-ui-release.apk"
      ;;
    bundle|release-aab)
      TASK=":app-ui:bundleRelease"
      OUTPUT_LABEL="AAB"
      OUTPUT_PATH="app-ui/build/outputs/bundle/release/app-ui-release.aab"
      ;;
    *)
      TASK=":app-ui:assembleDebug"
      OUTPUT_LABEL="APK"
      OUTPUT_PATH="app-ui/build/outputs/apk/debug/app-ui-debug.apk"
      ;;
  esac

  echo "==> Running Gradle task $TASK"
  ./gradlew "$TASK"
  echo "✅ $OUTPUT_LABEL: $ROOT/$OUTPUT_PATH"
fi
