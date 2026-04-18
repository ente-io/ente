#!/usr/bin/env bash
set -euo pipefail

# Bootstraps the local macOS prerequisites needed to archive Ensu.
#
# This script intentionally stops before provisioning and TestFlight upload.
# It covers the setup steps we had to take locally to make `archive` work:
#   1. Ensure required local developer tools are installed.
#   2. Ensure the required Rust Apple targets are installed.
#   3. Ensure the generated UniFFI Swift bindings already exist.
#   4. Resolve Swift package dependencies for the Xcode project.
#   5. Print the archive command to run next.
#
# Usage:
#   ./setup-mac.sh
#   ./setup-mac.sh --archive

ROOT="$(cd "$(dirname "$0")" && pwd)"
ARCHIVE_PATH="$ROOT/build/Archive/Ensu.xcarchive"

ARCHIVE_AFTER_SETUP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive)
      ARCHIVE_AFTER_SETUP=1
      shift
      ;;
    -h|--help)
      cat <<'EOF'
Prepare a Mac to archive Ensu locally.

Usage:
  ./setup-mac.sh [--archive]

Options:
  --archive   Run the archive command after setup succeeds.
EOF
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

print_step() {
  echo
  echo "==> $1"
}

require_command() {
  local name="$1"
  local hint="${2:-}"
  if command -v "$name" >/dev/null 2>&1; then
    return
  fi

  echo "Missing required command: $name" >&2
  if [[ -n "$hint" ]]; then
    echo "$hint" >&2
  fi
  exit 1
}

require_rust_target() {
  local target="$1"
  if rustup target list --installed | grep -qx "$target"; then
    return
  fi

  echo "Missing required Rust target: $target" >&2
  echo "Install Apple targets with:" >&2
  echo "  rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios" >&2
  exit 1
}

require_generated_bindings() {
  local generated_dir="$ROOT/Ensu/Generated"

  for binding in \
    "$generated_dir/core.swift" \
    "$generated_dir/coreFFI.h" \
    "$generated_dir/coreFFI.modulemap" \
    "$generated_dir/db.swift" \
    "$generated_dir/dbFFI.h" \
    "$generated_dir/dbFFI.modulemap" \
    "$generated_dir/sync.swift" \
    "$generated_dir/syncFFI.h" \
    "$generated_dir/syncFFI.modulemap" \
    "$generated_dir/inference.swift" \
    "$generated_dir/inferenceFFI.h" \
    "$generated_dir/inferenceFFI.modulemap"; do
    if [[ ! -f "$binding" ]]; then
      echo "Missing generated UniFFI Swift bindings under $generated_dir" >&2
      echo "Run the repo-local codegen step first:" >&2
      echo "  cd \"$ROOT/../../../../../rust\"" >&2
      echo "  cargo codegen ensu-ios" >&2
      exit 1
    fi
  done
}

print_step "Checking required local tools"
require_command xcodebuild "Install Xcode and Xcode command line tools."
require_command cargo "Install Rust and ensure cargo is on PATH."
require_command rustup "Install rustup and ensure it is on PATH."
require_command cmake "Install CMake, for example with 'brew install cmake'."
require_command lipo "Install Xcode command line tools and ensure lipo is on PATH."

print_step "Checking required Rust Apple targets"
require_rust_target aarch64-apple-ios
require_rust_target aarch64-apple-ios-sim
require_rust_target x86_64-apple-ios
print_step "Checking generated UniFFI Swift bindings"
require_generated_bindings
print_step "Resolving Swift package dependencies"
(
  cd "$ROOT"
  xcodebuild \
    -resolvePackageDependencies \
    -scheme Ensu
)

print_step "Setup complete"
cat <<EOF
Local archive prerequisites are ready.

Archive command:
  cd "$ROOT"
  xcodebuild \\
    -scheme Ensu \\
    -configuration Release \\
    -sdk iphoneos \\
    -destination 'generic/platform=iOS' \\
    -archivePath $ARCHIVE_PATH \\
    archive

Notes:
  - If the generated Swift bindings are missing, run:
      cd "$ROOT/../../../../../rust"
      cargo codegen ensu-ios
  - Provisioning/TestFlight export is intentionally not handled here.
  - If Xcode still shows missing package products, run:
      File > Packages > Resolve Package Versions
EOF

if [[ "$ARCHIVE_AFTER_SETUP" == "1" ]]; then
  print_step "Archiving Ensu"
  (
    cd "$ROOT"
    xcodebuild \
      -scheme Ensu \
      -configuration Release \
      -sdk iphoneos \
      -destination 'generic/platform=iOS' \
      -archivePath "$ARCHIVE_PATH" \
      archive
  )
fi
