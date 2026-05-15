#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
e2e_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
repo_dir=$(CDPATH= cd -- "$e2e_dir/../.." && pwd)
server_dir="$repo_dir/server"
endpoint="${ENTE_E2E_ENDPOINT:-http://localhost:18080}"
paste_origin="${ENTE_E2E_PASTE_ORIGIN:-http://localhost:3008}"
pglite_port="${ENTE_E2E_PGLITE_PORT:-15432}"
endpoint_port=$(printf '%s' "$endpoint" | sed -E 's#^https?://[^:]+:([0-9]+).*$#\1#')
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/ente-rust-e2e-pglite.XXXXXX")
credentials_yaml="$tmp_dir/credentials.yaml"
pglite_log="$tmp_dir/pglite.log"
museum_log="$tmp_dir/museum.log"
target_dir="${ENTE_E2E_TARGET_DIR:-$repo_dir/rust/target}"
cli_bin="$target_dir/debug/ente-rs"

dump_logs() {
    echo "pglite log: $pglite_log" >&2
    sed -n '1,240p' "$pglite_log" >&2 || true
    echo "museum log: $museum_log" >&2
    sed -n '1,240p' "$museum_log" >&2 || true
    echo "museum log tail: $museum_log" >&2
    tail -n 240 "$museum_log" >&2 || true
}

wait_for_pglite() {
    attempt=0
    until node -e '
const net = require("node:net");
const socket = net.connect(Number(process.argv[2]), process.argv[1]);
socket.once("connect", () => {
    socket.end();
    process.exit(0);
});
socket.once("error", () => process.exit(1));
setTimeout(() => process.exit(1), 500);
' 127.0.0.1 "$pglite_port"; do
        attempt=$((attempt + 1))
        if [ "$attempt" -ge 30 ]; then
            echo "PGlite did not start on 127.0.0.1:$pglite_port" >&2
            dump_logs
            exit 1
        fi
        if ! kill -0 "$pglite_pid" >/dev/null 2>&1; then
            echo "PGlite exited before accepting connections" >&2
            dump_logs
            exit 1
        fi
        sleep 1
    done
}

cleanup() {
    status=$?
    if [ -n "${museum_pid:-}" ]; then
        kill "$museum_pid" >/dev/null 2>&1 || true
        wait "$museum_pid" >/dev/null 2>&1 || true
    fi
    if [ -n "${pglite_pid:-}" ]; then
        kill "$pglite_pid" >/dev/null 2>&1 || true
        wait "$pglite_pid" >/dev/null 2>&1 || true
    fi
    rm -rf "$tmp_dir"
    exit "$status"
}

trap cleanup EXIT INT TERM

if [ -z "$endpoint_port" ] || [ "$endpoint_port" = "$endpoint" ]; then
    echo "ENTE_E2E_ENDPOINT must include an explicit host port, got: $endpoint" >&2
    exit 1
fi

cat >"$credentials_yaml" <<EOF
db:
    host: 127.0.0.1
    port: $pglite_port
    name: postgres
    user: postgres
    password: ""
    sslmode: disable

s3:
    are_local_buckets: true
    b2-eu-cen:
        key: changeme
        secret: changeme1234
        endpoint: localhost:3200
        region: eu-central-2
        bucket: b2-eu-cen
    wasabi-eu-central-2-v3:
        key: changeme
        secret: changeme1234
        endpoint: localhost:3200
        region: eu-central-2
        bucket: wasabi-eu-central-2-v3
        compliance: false
    scw-eu-fr-v3:
        key: changeme
        secret: changeme1234
        endpoint: localhost:3200
        region: eu-central-2
        bucket: scw-eu-fr-v3
EOF

(
    cd "$repo_dir/rust"
    cargo build -p ente-rs --target-dir "$target_dir" --bin ente-rs
)

npm exec --yes --package @electric-sql/pglite-socket pglite-server -- \
    --db=memory:// \
    --host=127.0.0.1 \
    --port="$pglite_port" \
    --max-connections=20 \
    >"$pglite_log" 2>&1 &
pglite_pid=$!
wait_for_pglite

(
    cd "$server_dir"
    ENTE_CREDENTIALS_FILE="$credentials_yaml" \
    ENTE_HTTP_PORT="$endpoint_port" \
    ENTE_APPS_PUBLIC_PASTE="$paste_origin" \
    ENTE_DB_HOST=127.0.0.1 \
    ENTE_DB_PORT="$pglite_port" \
    ENTE_DB_NAME=postgres \
    ENTE_DB_USER=postgres \
    ENTE_DB_PASSWORD="" \
    ENTE_DB_SSLMODE=disable \
    ENTE_INTERNAL_HARDCODED_OTT_LOCAL_DOMAIN_SUFFIX="@ente-rust-test.org" \
    ENTE_INTERNAL_HARDCODED_OTT_LOCAL_DOMAIN_VALUE=123456 \
    go run ./cmd/museum
) >"$museum_log" 2>&1 &
museum_pid=$!

attempt=0
until curl -fsS "$endpoint/ping" >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 90 ]; then
        echo "Museum did not become ready at $endpoint/ping" >&2
        dump_logs
        exit 1
    fi
    if ! kill -0 "$pglite_pid" >/dev/null 2>&1; then
        echo "PGlite exited before Museum became ready" >&2
        dump_logs
        exit 1
    fi
    if ! kill -0 "$museum_pid" >/dev/null 2>&1; then
        echo "Museum exited before becoming ready" >&2
        dump_logs
        exit 1
    fi
    sleep 2
done

cd "$repo_dir/rust"
export ENTE_E2E_ENDPOINT="$endpoint"
export ENTE_E2E_PASTE_ORIGIN="$paste_origin"
export ENTE_E2E_CLI_BIN="$cli_bin"
export ENTE_E2E_ONLY="${ENTE_E2E_ONLY:-paste_cli_e2e}"

if ! cargo test -p ente-e2e --target-dir "$target_dir" "$@" -- --ignored --nocapture; then
    dump_logs
    exit 1
fi
