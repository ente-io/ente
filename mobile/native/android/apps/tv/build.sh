#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

MODE="debug"
SKIP_RUST=0
SKIP_APP=0

usage() {
  cat <<'EOF'
Build Photos TV Android app.

Usage:
  ./build.sh [debug|apk|aab] [options]

Modes:
  debug  Build debug APK
  apk    Build release APK
  aab    Build release Android App Bundle (.aab)

Aliases (still supported):
  release, release-apk => apk
  bundle, release-aab  => aab

Options:
  --skip-rust          Skip Rust/jni build step
  --skip-app           Skip Gradle app build step
  -h, --help           Show help

Examples:
  ./build.sh
  ./build.sh apk
  ./build.sh aab
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    debug|apk|aab|release|release-apk|bundle|release-aab)
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

if [[ "$SKIP_RUST" -eq 0 ]]; then
  echo "==> Building Rust Android artifacts"
  ./gradlew buildEnteCore
fi

if [[ "$SKIP_APP" -eq 0 ]]; then
  case "$MODE" in
    apk|release|release-apk)
      TASK=":app:assembleRelease"
      OUTPUT_LABEL="APK"
      OUTPUT_PATH="app/build/outputs/apk/release/app-release.apk"
      ;;
    aab|bundle|release-aab)
      TASK=":app:bundleRelease"
      OUTPUT_LABEL="AAB"
      OUTPUT_PATH="app/build/outputs/bundle/release/app-release.aab"
      ;;
    *)
      TASK=":app:assembleDebug"
      OUTPUT_LABEL="APK"
      OUTPUT_PATH="app/build/outputs/apk/debug/app-debug.apk"
      ;;
  esac

  echo "==> Running Gradle task $TASK"
  ./gradlew "$TASK"
  echo "✅ $OUTPUT_LABEL: $ROOT/$OUTPUT_PATH"
fi
