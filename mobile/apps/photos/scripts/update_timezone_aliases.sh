#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

tmp_dir=$(mktemp -d)
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

archive="$tmp_dir/tzdata.tar.gz"
backward="$tmp_dir/backward"

curl -L https://data.iana.org/time-zones/tzdata-latest.tar.gz -o "$archive"
tar -xzf "$archive" -C "$tmp_dir" backward

cd "$repo_root"
dart run scripts/generate_timezone_aliases.dart "$backward" lib/services/timezone_aliases.dart
