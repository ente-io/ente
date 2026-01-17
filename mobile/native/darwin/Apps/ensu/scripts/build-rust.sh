#!/bin/sh
set -euo pipefail

# Build the UniFFI Rust static library for the current Xcode build platform.
#
# Outputs a universal static library at:
#   $TARGET_TEMP_DIR/ensu_rust/libensu_uniffi.a

if [ -z "${SRCROOT:-}" ] || [ -z "${TARGET_TEMP_DIR:-}" ] || [ -z "${PLATFORM_NAME:-}" ] || [ -z "${ARCHS:-}" ]; then
  echo "Missing required Xcode environment variables (SRCROOT/TARGET_TEMP_DIR/PLATFORM_NAME/ARCHS)" >&2
  exit 1
fi

REPO_ROOT="$(cd "${SRCROOT}/../../../../.." && pwd)"
CRATE_DIR="${REPO_ROOT}/rust/ensu_uniffi"
OUT_DIR="${TARGET_TEMP_DIR}/ensu_rust"

mkdir -p "${OUT_DIR}"

# Use debug profile for Debug builds to speed iteration.
CARGO_FLAGS="--locked"
PROFILE="debug"
if [ "${CONFIGURATION:-Debug}" = "Release" ]; then
  CARGO_FLAGS="${CARGO_FLAGS} --release"
  PROFILE="release"
fi

# Map Xcode platform+arch to Rust target triple.
# Note: For iOS simulator on arm64, Rust uses aarch64-apple-ios-sim.
rust_target_for() {
  platform="$1"
  arch="$2"

  case "$platform" in
    iphoneos)
      if [ "$arch" = "arm64" ]; then
        echo "aarch64-apple-ios"
      else
        echo "" # unsupported
      fi
      ;;
    iphonesimulator)
      if [ "$arch" = "arm64" ]; then
        echo "aarch64-apple-ios-sim"
      elif [ "$arch" = "x86_64" ]; then
        echo "x86_64-apple-ios"
      else
        echo "" # unsupported
      fi
      ;;
    macosx)
      if [ "$arch" = "arm64" ]; then
        echo "aarch64-apple-darwin"
      elif [ "$arch" = "x86_64" ]; then
        echo "x86_64-apple-darwin"
      else
        echo "" # unsupported
      fi
      ;;
    *)
      echo "" # unsupported
      ;;
  esac
}

sdk_for_platform() {
  platform="$1"
  case "$platform" in
    iphoneos)
      echo "iphoneos";
      ;;
    iphonesimulator)
      echo "iphonesimulator";
      ;;
    macosx)
      echo "macosx";
      ;;
    *)
      echo "";
      ;;
  esac
}

TARGET_SDK_NAME="$(sdk_for_platform "${PLATFORM_NAME}")"
if [ -z "${TARGET_SDK_NAME}" ]; then
  echo "Unsupported platform: ${PLATFORM_NAME}" >&2
  exit 1
fi

TARGET_SDKROOT="$(xcrun --sdk "${TARGET_SDK_NAME}" --show-sdk-path)"
TARGET_CLANG="$(xcrun --sdk "${TARGET_SDK_NAME}" --find clang)"
HOST_SDKROOT="$(xcrun --sdk macosx --show-sdk-path)"

# Ensure host builds (build scripts) use the macOS SDK.
export SDKROOT="${HOST_SDKROOT}"

# Build per-arch and then lipo into a universal static library for this platform.
INPUT_LIBS=""

for arch in ${ARCHS}; do
  target="$(rust_target_for "${PLATFORM_NAME}" "$arch")"
  if [ -z "$target" ]; then
    echo "Skipping unsupported arch/platform: ${PLATFORM_NAME} ${arch}" >&2
    continue
  fi

  # Ensure target is installed.
  if ! rustup target list --installed | grep -q "^${target}$"; then
    echo "Installing Rust target ${target}..."
    rustup target add "${target}"
  fi

  target_env="$(echo "${target}" | tr '[:lower:]-' '[:upper:]_')"

  # Linker + sysroot for the target.
  eval "export CARGO_TARGET_${target_env}_LINKER=\"${TARGET_CLANG}\""
  eval "export CFLAGS_${target_env}=\"-isysroot ${TARGET_SDKROOT}\""
  eval "export CXXFLAGS_${target_env}=\"-isysroot ${TARGET_SDKROOT}\""

  # Pass the SDK root to the linker explicitly (important when SDKROOT is macOS).
  RUSTFLAGS_TARGET="${RUSTFLAGS:-} -C link-arg=-isysroot -C link-arg=${TARGET_SDKROOT}"
  if [ "${PLATFORM_NAME}" = "iphonesimulator" ] && [ -n "${IPHONEOS_DEPLOYMENT_TARGET:-}" ]; then
    RUSTFLAGS_TARGET="${RUSTFLAGS_TARGET} -C link-arg=-mios-simulator-version-min=${IPHONEOS_DEPLOYMENT_TARGET}"
  elif [ "${PLATFORM_NAME}" = "iphoneos" ] && [ -n "${IPHONEOS_DEPLOYMENT_TARGET:-}" ]; then
    RUSTFLAGS_TARGET="${RUSTFLAGS_TARGET} -C link-arg=-miphoneos-version-min=${IPHONEOS_DEPLOYMENT_TARGET}"
  fi

  echo "Building ensu_uniffi for ${PLATFORM_NAME} ${arch} (${target}) [${PROFILE}]"
  (cd "${CRATE_DIR}" && RUSTFLAGS="${RUSTFLAGS_TARGET}" cargo build ${CARGO_FLAGS} --target "${target}")

  lib_path="${CRATE_DIR}/target/${target}/${PROFILE}/libensu_uniffi.a"
  if [ ! -f "${lib_path}" ]; then
    echo "Expected library not found: ${lib_path}" >&2
    exit 1
  fi

  arch_lib="${OUT_DIR}/libensu_uniffi_${arch}.a"
  cp "${lib_path}" "${arch_lib}"
  INPUT_LIBS="${INPUT_LIBS} ${arch_lib}"

done

# Create universal lib.
UNIVERSAL_LIB="${OUT_DIR}/libensu_uniffi.a"
rm -f "${UNIVERSAL_LIB}"

# If we have only one arch, just copy.
set -- ${INPUT_LIBS}
if [ "$#" -eq 1 ]; then
  cp "$1" "${UNIVERSAL_LIB}"
else
  lipo -create ${INPUT_LIBS} -output "${UNIVERSAL_LIB}"
fi

echo "✅ Built ${UNIVERSAL_LIB}"
