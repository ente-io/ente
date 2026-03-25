#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
server_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
compose_file="$server_dir/compose.test.yaml"

cleanup() {
    docker compose -f "$compose_file" down -v --remove-orphans >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

cd "$server_dir"
docker compose -f "$compose_file" build server-test
docker compose -f "$compose_file" up -d postgres-test
docker compose -f "$compose_file" run --rm server-test ./scripts/run-go-tests-in-container.sh "$@"
