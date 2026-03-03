#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENCRYPTO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CRATE_DIR="${SCRIPT_DIR}"
BINARY_DIR="${ENCRYPTO_DIR}/Binaries"
XCFRAMEWORK_DIR="${BINARY_DIR}/EnteRustCryptoFFI.xcframework"
HEADER_DIR="${CRATE_DIR}/include"
TARGET_DIR="${CRATE_DIR}/target"
LIB_NAME="libente_tvos_crypto_ffi.a"
WORK_DIR="${TARGET_DIR}/xcframework-build"
FALLBACK_TOOLCHAIN="nightly"

IOS_DEVICE_TARGET="aarch64-apple-ios"
IOS_SIM_ARM_TARGET="aarch64-apple-ios-sim"
IOS_SIM_X86_TARGET="x86_64-apple-ios"
TVOS_DEVICE_TARGET="aarch64-apple-tvos"
TVOS_SIM_ARM_TARGET="aarch64-apple-tvos-sim"
TVOS_SIM_X86_TARGET="x86_64-apple-tvos"
MACOS_ARM_TARGET="aarch64-apple-darwin"
MACOS_X86_TARGET="x86_64-apple-darwin"

for tool in cargo rustup xcodebuild lipo; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "error: required tool not found: ${tool}" >&2
        exit 1
    fi
done

TARGETS=(
    "${IOS_DEVICE_TARGET}"
    "${IOS_SIM_ARM_TARGET}"
    "${IOS_SIM_X86_TARGET}"
    "${TVOS_DEVICE_TARGET}"
    "${TVOS_SIM_ARM_TARGET}"
    "${TVOS_SIM_X86_TARGET}"
    "${MACOS_ARM_TARGET}"
    "${MACOS_X86_TARGET}"
)

nightly_ready=0
build_target() {
    local target="$1"

    if rustup target add "${target}" >/dev/null 2>&1; then
        cargo build --manifest-path "${CRATE_DIR}/Cargo.toml" --release --target "${target}"
        return
    fi

    if [[ "${nightly_ready}" -eq 0 ]]; then
        echo "==> Falling back to ${FALLBACK_TOOLCHAIN} with build-std for unsupported Apple targets"
        rustup toolchain install "${FALLBACK_TOOLCHAIN}" --profile minimal
        rustup component add rust-src --toolchain "${FALLBACK_TOOLCHAIN}"
        nightly_ready=1
    fi

    cargo +"${FALLBACK_TOOLCHAIN}" build -Z build-std --manifest-path "${CRATE_DIR}/Cargo.toml" --release --target "${target}"
}

echo "==> Building static libraries"
for target in "${TARGETS[@]}"; do
    echo "   -> ${target}"
    build_target "${target}"
done

mkdir -p "${WORK_DIR}"

IOS_SIM_LIB="${WORK_DIR}/libente_tvos_crypto_ffi-iossim.a"
TVOS_SIM_LIB="${WORK_DIR}/libente_tvos_crypto_ffi-tvossim.a"
MACOS_UNIVERSAL_LIB="${WORK_DIR}/libente_tvos_crypto_ffi-macos.a"

echo "==> Creating universal simulator and macOS slices"
lipo -create \
    -output "${IOS_SIM_LIB}" \
    "${TARGET_DIR}/${IOS_SIM_ARM_TARGET}/release/${LIB_NAME}" \
    "${TARGET_DIR}/${IOS_SIM_X86_TARGET}/release/${LIB_NAME}"

lipo -create \
    -output "${TVOS_SIM_LIB}" \
    "${TARGET_DIR}/${TVOS_SIM_ARM_TARGET}/release/${LIB_NAME}" \
    "${TARGET_DIR}/${TVOS_SIM_X86_TARGET}/release/${LIB_NAME}"

lipo -create \
    -output "${MACOS_UNIVERSAL_LIB}" \
    "${TARGET_DIR}/${MACOS_ARM_TARGET}/release/${LIB_NAME}" \
    "${TARGET_DIR}/${MACOS_X86_TARGET}/release/${LIB_NAME}"

mkdir -p "${BINARY_DIR}"
rm -rf "${XCFRAMEWORK_DIR}"

echo "==> Building EnteRustCryptoFFI.xcframework"
xcodebuild -create-xcframework \
    -library "${TARGET_DIR}/${IOS_DEVICE_TARGET}/release/${LIB_NAME}" -headers "${HEADER_DIR}" \
    -library "${IOS_SIM_LIB}" -headers "${HEADER_DIR}" \
    -library "${TARGET_DIR}/${TVOS_DEVICE_TARGET}/release/${LIB_NAME}" -headers "${HEADER_DIR}" \
    -library "${TVOS_SIM_LIB}" -headers "${HEADER_DIR}" \
    -library "${MACOS_UNIVERSAL_LIB}" -headers "${HEADER_DIR}" \
    -output "${XCFRAMEWORK_DIR}"

echo "==> Done: ${XCFRAMEWORK_DIR}"
