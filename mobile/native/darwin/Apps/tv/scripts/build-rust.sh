#!/bin/sh
set -eu

REPO_ROOT=$(cd "$SRCROOT/../../../../.." && pwd)
OUT_DIR="$TARGET_TEMP_DIR/ente_crypto_rust"
LIB=libente_crypto_ffi.a

export PATH="${CARGO_HOME:-$HOME/.cargo}/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

mkdir -p "$OUT_DIR"

case "${CONFIGURATION:-Debug}" in
    Release) profile=release; release_flag=--release ;;
    *) profile=debug; release_flag= ;;
esac

sdk=$(xcrun --sdk "$PLATFORM_NAME" --show-sdk-path)
clang=$(xcrun --sdk "$PLATFORM_NAME" --find clang)
libs=

for arch in $ARCHS; do
    case "$PLATFORM_NAME:$arch" in
        appletvos:arm64) target=aarch64-apple-tvos; min_flag=-mtvos-version-min ;;
        appletvsimulator:arm64) target=aarch64-apple-tvos-sim; min_flag=-mtvos-simulator-version-min ;;
        appletvsimulator:x86_64) target=x86_64-apple-tvos; min_flag=-mtvos-simulator-version-min ;;
        *) echo "unsupported arch: $PLATFORM_NAME/$arch" >&2; exit 1 ;;
    esac

    rustflags="-C linker=$clang -C link-arg=-isysroot -C link-arg=$sdk"
    if [ -n "${TVOS_DEPLOYMENT_TARGET:-}" ]; then
        rustflags="$rustflags -C link-arg=$min_flag=$TVOS_DEPLOYMENT_TARGET"
    fi

    (
        cd "$REPO_ROOT/rust"
        CC="$clang" \
            CFLAGS="-isysroot $sdk" \
            CARGO_TARGET_DIR="$REPO_ROOT/rust/target" \
            RUSTFLAGS="$rustflags" \
            cargo +nightly build -Z build-std --locked -p ente_crypto_ffi --target "$target" $release_flag
    )

    built="$REPO_ROOT/rust/target/$target/$profile/$LIB"
    cp "$built" "$OUT_DIR/$arch.a"
    libs="$libs $OUT_DIR/$arch.a"
done

set -- $libs
if [ "$#" -eq 1 ]; then
    cp "$1" "$OUT_DIR/$LIB"
else
    lipo -create "$@" -output "$OUT_DIR/$LIB"
fi
