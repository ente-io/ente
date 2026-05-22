#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

[[ $# -eq 1 ]] || {
    echo "Usage: $0 fdroid-vX.Y.Z" >&2
    exit 1
}

tag="$1"
version=$(awk '/^version:/ { print $2 }' pubspec.yaml | cut -d "+" -f 1)

[[ "$tag" == fdroid-v* ]] || {
    echo "create_tag: expected fdroid-v tag" >&2
    exit 1
}

[[ "${tag#fdroid-v}" == "$version" ]] || {
    echo "create_tag: pubspec version $version does not match $tag" >&2
    exit 1
}

./scripts/check_fdroid_overlay.sh
git tag "$tag"
echo "Tag $tag created."
