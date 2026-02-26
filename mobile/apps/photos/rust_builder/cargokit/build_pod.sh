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

  # ort-sys currently does not handle x86_64 iOS simulator triples for
  # ORT_IOS_XCFWK_LOCATION, so provide ORT_LIB_LOCATION with a thin archive.
  if [[ "$CARGOKIT_DARWIN_PLATFORM_NAME" == "iphonesimulator" ]] && [[ "$CARGOKIT_DARWIN_ARCHS" == "x86_64" ]]; then
    ORT_SIM_LIB="$ORT_XCFWK_LOCATION/ios-arm64_x86_64-simulator/onnxruntime.framework/onnxruntime"
    if [[ -f "$ORT_SIM_LIB" ]]; then
      ORT_LIB_TEMP_DIR="$TARGET_TEMP_DIR/ort_sys_sim_x86_64"
      mkdir -p "$ORT_LIB_TEMP_DIR"
      lipo -thin x86_64 "$ORT_SIM_LIB" -output "$ORT_LIB_TEMP_DIR/libonnxruntime.a"
      export ORT_LIB_LOCATION="$ORT_LIB_TEMP_DIR"

      # Link the simulator clang runtime; ort-sys links the device variant for
      # x86_64-apple-ios, which misses simulator-only symbols.
      CLANG_RESOURCE_DIR="$(xcrun clang --print-resource-dir 2>/dev/null || true)"
      if [[ -n "$CLANG_RESOURCE_DIR" ]] && [[ -d "$CLANG_RESOURCE_DIR/lib/darwin" ]]; then
        export RUSTFLAGS="${RUSTFLAGS} -L native=${CLANG_RESOURCE_DIR}/lib/darwin -l clang_rt.iossim"
      fi
    fi
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
