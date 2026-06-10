#!/bin/sh

# Package the built "Ente Auth.app" into a styled DMG using only tools that
# ship with macOS.
#
#     make-dmg.sh path/to/Ente\ Auth.app out.dmg
#
# The Finder appearance (window size, icon positions) comes from the
# committed DS_Store; the commit that introduced it has the regeneration
# recipe.

set -eu

app=$1
out=$2

dir=$(cd "$(dirname "$0")" && pwd)
staging=$(mktemp -d)
trap 'rm -rf "$staging"' EXIT

mkdir "$staging/root"
cp -R "$app" "$staging/root/Ente Auth.app"
ln -s /Applications "$staging/root/Applications"
cp "$dir/DS_Store" "$staging/root/.DS_Store"

icon="$dir/../../../assets/generation-icons/icon-macos.png"
mkdir "$staging/vol.iconset"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$icon" \
        --out "$staging/vol.iconset/icon_${size}x${size}.png" >/dev/null
    sips -z "$((size * 2))" "$((size * 2))" "$icon" \
        --out "$staging/vol.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil --convert icns "$staging/vol.iconset" \
    --output "$staging/root/.VolumeIcon.icns"

hdiutil create -volname Auth -fs HFS+ -format UDRW \
    -srcfolder "$staging/root" -ov "$staging/rw.dmg"

# The kHasCustomIcon Finder flag must be set on the mounted volume root; it
# does not survive the -srcfolder copy.
hdiutil attach "$staging/rw.dmg" -noautoopen -mountpoint "$staging/mnt"
xattr -wx com.apple.FinderInfo \
    "0000000000000000040000000000000000000000000000000000000000000000" \
    "$staging/mnt"
hdiutil detach "$staging/mnt"

hdiutil convert "$staging/rw.dmg" -format UDZO -ov -o "$out"
