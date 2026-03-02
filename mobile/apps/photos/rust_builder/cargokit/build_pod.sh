#!/bin/sh
set -e

BASEDIR=$(dirname "$0")

# Workaround for https://github.com/dart-lang/pub/issues/4010
BASEDIR=$(cd "$BASEDIR" ; pwd -P)

# Remove XCode SDK from path. Otherwise this breaks tool compilation when building iOS project
NEW_PATH=`echo $PATH | tr ":" "\n" | grep -v "Contents/Developer/" | tr "\n" ":"`

export PATH=${NEW_PATH%?} # remove trailing :

env

# Platform name (macosx, iphoneos, iphonesimulator)
export CARGOKIT_DARWIN_PLATFORM_NAME=$PLATFORM_NAME

# Arctive architectures (arm64, armv7, x86_64), space separated.
export CARGOKIT_DARWIN_ARCHS=$ARCHS

# Current build configuration (Debug, Release)
export CARGOKIT_CONFIGURATION=$CONFIGURATION

# Path to directory containing Cargo.toml.
export CARGOKIT_MANIFEST_DIR=$PODS_TARGET_SRCROOT/$1

# Temporary directory for build artifacts.
export CARGOKIT_TARGET_TEMP_DIR=$TARGET_TEMP_DIR

# Output directory for final artifacts.
export CARGOKIT_OUTPUT_DIR=$PODS_CONFIGURATION_BUILD_DIR/$PRODUCT_NAME

# Directory to store built tool artifacts.
export CARGOKIT_TOOL_TEMP_DIR=$TARGET_TEMP_DIR/build_tool

# Directory inside root project. Not necessarily the top level directory of root project.
export CARGOKIT_ROOT_PROJECT_DIR=$SRCROOT

# Configure ort-sys to link against the ONNX Runtime iOS xcframework instead of
# relying on runtime dylib loading.
if [[ -n "$PODS_ROOT" ]] && [[ -d "$PODS_ROOT/onnxruntime-c/onnxruntime.xcframework" ]]; then
  ORT_XCFWK_LOCATION="$PODS_ROOT/onnxruntime-c/onnxruntime.xcframework"
  export ORT_IOS_XCFWK_LOCATION="$ORT_XCFWK_LOCATION"

  # ort-sys 2.0.0-rc.4 (used in this repo) only respects ORT_LIB_LOCATION.
  # Build a per-target static archive named libonnxruntime.a so it can link
  # against ONNX Runtime from the CocoaPods xcframework.
  ORT_ARCHIVE_SOURCE=""
  ORT_ARCHIVE_ARCH=""
  if [[ "$CARGOKIT_DARWIN_PLATFORM_NAME" == "iphoneos" ]]; then
    ORT_ARCHIVE_SOURCE="$ORT_XCFWK_LOCATION/ios-arm64/onnxruntime.framework/onnxruntime"
    ORT_ARCHIVE_ARCH="arm64"
  elif [[ "$CARGOKIT_DARWIN_PLATFORM_NAME" == "iphonesimulator" ]]; then
    ORT_ARCHIVE_SOURCE="$ORT_XCFWK_LOCATION/ios-arm64_x86_64-simulator/onnxruntime.framework/onnxruntime"
    if [[ "$CARGOKIT_DARWIN_ARCHS" == "x86_64" ]]; then
      ORT_ARCHIVE_ARCH="x86_64"
    elif [[ "$CARGOKIT_DARWIN_ARCHS" == "arm64" ]]; then
      ORT_ARCHIVE_ARCH="arm64"
    fi
  fi

  if [[ -n "$ORT_ARCHIVE_SOURCE" ]] && [[ -f "$ORT_ARCHIVE_SOURCE" ]]; then
    ORT_LIB_TEMP_DIR="$TARGET_TEMP_DIR/ort_sys_${CARGOKIT_DARWIN_PLATFORM_NAME}_${CARGOKIT_DARWIN_ARCHS// /_}"
    mkdir -p "$ORT_LIB_TEMP_DIR"
    if [[ -n "$ORT_ARCHIVE_ARCH" ]]; then
      lipo -thin "$ORT_ARCHIVE_ARCH" "$ORT_ARCHIVE_SOURCE" -output "$ORT_LIB_TEMP_DIR/libonnxruntime.a"
    else
      cp "$ORT_ARCHIVE_SOURCE" "$ORT_LIB_TEMP_DIR/libonnxruntime.a"
    fi
    export ORT_LIB_LOCATION="$ORT_LIB_TEMP_DIR"
  fi

  # ONNX Runtime archives can reference availability helpers from clang runtime.
  # Explicitly link the platform-appropriate clang runtime for Rust linking.
  CLANG_RUNTIME_LIB=""
  if [[ "$CARGOKIT_DARWIN_PLATFORM_NAME" == "iphoneos" ]]; then
    CLANG_RUNTIME_LIB="clang_rt.ios"
  elif [[ "$CARGOKIT_DARWIN_PLATFORM_NAME" == "iphonesimulator" ]]; then
    CLANG_RUNTIME_LIB="clang_rt.iossim"
  fi
  CLANG_RESOURCE_DIR="$(xcrun clang --print-resource-dir 2>/dev/null || true)"
  if [[ -n "$CLANG_RUNTIME_LIB" ]] && [[ -n "$CLANG_RESOURCE_DIR" ]] && [[ -d "$CLANG_RESOURCE_DIR/lib/darwin" ]]; then
    export RUSTFLAGS="${RUSTFLAGS} -L native=${CLANG_RESOURCE_DIR}/lib/darwin -l ${CLANG_RUNTIME_LIB}"
  fi
fi

FLUTTER_EXPORT_BUILD_ENVIRONMENT=(
  "$PODS_ROOT/../Flutter/ephemeral/flutter_export_environment.sh" # macOS
  "$PODS_ROOT/../Flutter/flutter_export_environment.sh" # iOS
)

for path in "${FLUTTER_EXPORT_BUILD_ENVIRONMENT[@]}"
do
  if [[ -f "$path" ]]; then
    source "$path"
  fi
done

sh "$BASEDIR/run_build_tool.sh" build-pod "$@"

# Make a symlink from built framework to phony file, which will be used as input to
# build script. This should force rebuild (podspec currently doesn't support alwaysOutOfDate
# attribute on custom build phase)
ln -fs "$OBJROOT/XCBuildData/build.db" "${BUILT_PRODUCTS_DIR}/cargokit_phony"
ln -fs "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_PATH}" "${BUILT_PRODUCTS_DIR}/cargokit_phony_out"
