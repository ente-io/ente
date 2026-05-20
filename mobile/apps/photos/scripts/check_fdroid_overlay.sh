#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
app_root=$(pwd)

fail() {
    echo "check_fdroid_overlay: $*" >&2
    exit 1
}

repo_root=$(git rev-parse --show-toplevel)
app_rel=${app_root#"$repo_root"/}
tmp_root=$(mktemp -d "${TMPDIR:-/tmp}/ente-photos-fdroid.XXXXXX")
worktree="$tmp_root/worktree"

cleanup() {
    local status=$?
    git -C "$repo_root" worktree remove --force "$worktree" >/dev/null 2>&1 || true
    rm -rf "$tmp_root"
    exit "$status"
}
trap cleanup EXIT

git -C "$repo_root" worktree add --detach "$worktree" HEAD >/dev/null

git -C "$repo_root" diff --binary HEAD -- "$app_rel" .github/workflows/mobile-release.yml > "$tmp_root/current.patch"
if [[ -s "$tmp_root/current.patch" ]]; then
    git -C "$worktree" apply "$tmp_root/current.patch"
fi

while IFS= read -r -d "" file; do
    mkdir -p "$worktree/$(dirname "$file")"
    cp -p "$repo_root/$file" "$worktree/$file"
done < <(
    git -C "$repo_root" ls-files \
        --others \
        --exclude-standard \
        -z \
        -- "$app_rel"
)

cd "$worktree/mobile/apps/photos"

./scripts/prepare_fdroid_source.sh
flutter pub get

if rg -n "firebase_core|firebase_messaging|in_app_purchase" pubspec.yaml pubspec.lock; then
    fail "restricted dependencies remain after flutter pub get"
fi

command -v flutter_rust_bridge_codegen >/dev/null \
    || fail "flutter_rust_bridge_codegen is required; install it with cargo install flutter_rust_bridge_codegen"

pushd ../../packages/rust >/dev/null
flutter_rust_bridge_codegen generate
popd >/dev/null
flutter_rust_bridge_codegen generate

flutter analyze --no-pub
flutter build apk \
    --config-only \
    --flavor fdroid \
    -t lib/main.dart \
    --dart-define=cronetHttpNoPlay=true \
    --no-pub
