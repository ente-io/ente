#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
e2e_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
repo_dir=$(CDPATH= cd -- "$e2e_dir/../.." && pwd)
fixture_dir="$e2e_dir/fixtures/server"
compose_file="$fixture_dir/compose.auth.yaml"
museum_yaml="$fixture_dir/museum.yaml"
endpoint="${ENTE_E2E_ENDPOINT:-http://localhost:18080}"
project_name="${ENTE_E2E_DOCKER_PROJECT:-ente-rust-e2e}"
endpoint_port=$(printf '%s' "$endpoint" | sed -E 's#^https?://[^:]+:([0-9]+).*$#\1#')

compose() {
    docker compose -p "$project_name" -f "$compose_file" "$@"
}

dump_logs() {
    compose logs --no-color >&2 || true
}

if [ -z "$endpoint_port" ] || [ "$endpoint_port" = "$endpoint" ]; then
    echo "ENTE_E2E_ENDPOINT must include an explicit host port, got: $endpoint" >&2
    exit 1
fi

cleanup() {
    compose down -v --remove-orphans >/dev/null 2>&1 || true
    rm -f "$museum_yaml"
}

trap cleanup EXIT INT TERM

cat >"$museum_yaml" <<'EOF'
internal:
  hardcoded-ott:
    local-domain-suffix: "@ente-rust-test.org"
    local-domain-value: 123456
EOF

export ENTE_MUSEUM_PORT="$endpoint_port"
if ! compose up -d --build postgres museum; then
    dump_logs
    exit 1
fi

attempt=0
until curl -fsS "$endpoint/ping" >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 60 ]; then
        echo "Museum did not become ready at $endpoint/ping" >&2
        dump_logs
        exit 1
    fi
    sleep 2
done

cd "$repo_dir"
export ENTE_E2E_ENDPOINT="$endpoint"

if [ "$#" -gt 0 ]; then
    if ! cargo test --manifest-path rust/e2e/Cargo.toml "$@" -- --ignored --nocapture; then
        dump_logs
        exit 1
    fi
else
    if ! cargo test --manifest-path rust/e2e/Cargo.toml -- --ignored --nocapture; then
        dump_logs
        exit 1
    fi
fi
