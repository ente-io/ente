#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
server_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
test_db="ente_test_$(date +%Y%m%d%H%M%S)_$$"
pg_port="${ENTE_TEST_PGPORT:-45432}"
postgres_mode="${ENTE_TEST_POSTGRES:-auto}"
container_name="ente-server-test-postgres-$$"

is_local_target() {
    case "${1:-}" in
        ""|localhost|127.0.0.1|::1|/var/run/postgresql|/tmp)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

cleanup() {
    if [ "$postgres_mode" = "docker" ]; then
        docker rm -f "$container_name" >/dev/null 2>&1 || true
        return
    fi

    psql -v ON_ERROR_STOP=1 -d postgres >/dev/null 2>&1 <<SQL || true
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = '$test_db';

DROP DATABASE IF EXISTS "$test_db";
SQL
}

start_docker_postgres() {
    docker run --detach --rm \
        --name "$container_name" \
        --env POSTGRES_DB="$test_db" \
        --env POSTGRES_PASSWORD=test_pass \
        --publish "127.0.0.1:$pg_port:5432" \
        postgres:15 >/dev/null

    attempts=30
    while [ "$attempts" -gt 0 ]; do
        if docker exec "$container_name" pg_isready -q -h localhost -p 5432 -d "$test_db" -U postgres; then
            return
        fi
        attempts=$((attempts - 1))
        sleep 1
    done
    echo "Postgres did not become ready after 30 seconds." >&2
    exit 1
}

create_local_db() {
    if ! command -v psql >/dev/null 2>&1; then
        echo "psql is required when using local Postgres." >&2
        exit 1
    fi
    if [ -n "${DATABASE_URL:-}" ] || [ -n "${PGSERVICE:-}" ] || [ -n "${PGSERVICEFILE:-}" ]; then
        echo "Refusing DATABASE_URL/PGSERVICE/PGSERVICEFILE; they can redirect psql to another database." >&2
        exit 1
    fi
    if [ "${ALLOW_NONLOCAL_TEST_DB:-0}" != "1" ]; then
        if ! is_local_target "${PGHOST:-}"; then
            echo "Refusing non-local PGHOST=${PGHOST}. Set ALLOW_NONLOCAL_TEST_DB=1 to override." >&2
            exit 1
        fi
        if ! is_local_target "${PGHOSTADDR:-}"; then
            echo "Refusing non-local PGHOSTADDR=${PGHOSTADDR}. Set ALLOW_NONLOCAL_TEST_DB=1 to override." >&2
            exit 1
        fi
    fi

    if [ -z "${PGHOST:-}" ] && [ -z "${PGHOSTADDR:-}" ]; then
        export PGHOST=localhost
    fi
    psql -v ON_ERROR_STOP=1 -d postgres <<SQL
CREATE DATABASE "$test_db";
SQL
}

cd "$server_dir"

case "$postgres_mode" in
    auto)
        if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
            postgres_mode=docker
        else
            postgres_mode=local
        fi
        ;;
    docker|local)
        ;;
    *)
        echo "Unsupported ENTE_TEST_POSTGRES=$postgres_mode. Use auto, docker, or local." >&2
        exit 1
        ;;
esac

if [ "$postgres_mode" = "docker" ]; then
    trap cleanup EXIT INT TERM
    start_docker_postgres
    ENV=test PGHOST=localhost PGPORT="$pg_port" PGUSER=postgres PGPASSWORD=test_pass PGDATABASE="$test_db" go test -p 1 -count=1 "$@" ./...
else
    create_local_db
    trap cleanup EXIT INT TERM
    ENV=test PGDATABASE="$test_db" go test -p 1 -count=1 "$@" ./...
fi
