#!/bin/sh

# Runs the server test suite against a disposable Postgres database on either:
#
# * docker - creates a temporary Postgres container in Docker;
#
# * host - uses the existing Postgres on localhost.
#
# See RUNNING.md for more details.

set -eu

cd "$(dirname "$0")/.."

test_db="ente_test_$(date +%Y%m%d%H%M%S)_$$"
mode="${1:-}"

case "$mode" in
    docker | host) shift ;;
    *) echo "usage: $0 <docker|host> [go test flags]" >&2; exit 1 ;;
esac

if [ "$mode" = docker ]; then
    container="ente-server-test-postgres-$$"
    trap 'docker rm -f "$container" >/dev/null 2>&1 || true' EXIT INT TERM
    docker run --detach --rm \
        --name "$container" \
        --env POSTGRES_DB="$test_db" \
        --env POSTGRES_PASSWORD=test_pass \
        --publish 127.0.0.1::5432 \
        postgres:15 >/dev/null
    port=$(docker port "$container" 5432/tcp)
    port=${port##*:}
    # Probe over TCP: the socket-only temporary server that runs during
    # the image's first-boot initialization must not count as ready.
    i=0
    until docker exec "$container" pg_isready -q -h localhost -U postgres; do
        i=$((i + 1))
        [ "$i" -lt 30 ] || { echo "Postgres not ready after 30s." >&2; exit 1; }
        sleep 1
    done
    export PGHOST=localhost PGPORT="$port" PGUSER=postgres PGPASSWORD=test_pass
else
    # Guard the psql below from being redirected to a non-local cluster.
    [ -z "${DATABASE_URL:-}${PGSERVICE:-}${PGSERVICEFILE:-}" ] || {
        echo "Refusing DATABASE_URL/PGSERVICE/PGSERVICEFILE; they can redirect psql to another database." >&2
        exit 1
    }
    for host in "${PGHOST:-}" "${PGHOSTADDR:-}"; do
        case "$host" in
            "" | localhost | 127.0.0.1 | ::1 | /var/run/postgresql | /tmp) ;;
            *)
                [ "${ALLOW_NONLOCAL_TEST_DB:-}" = 1 ] || {
                    echo "Refusing non-local Postgres target $host. Set ALLOW_NONLOCAL_TEST_DB=1 to override." >&2
                    exit 1
                }
                ;;
        esac
    done
    # psql defaults to the unix socket while lib/pq defaults to TCP
    # localhost; pin both to the same server.
    [ -n "${PGHOST:-}${PGHOSTADDR:-}" ] || export PGHOST=localhost
    psql -qd postgres -c "CREATE DATABASE \"$test_db\""
    trap 'psql -qd postgres -c "DROP DATABASE IF EXISTS \"$test_db\" WITH (FORCE)" >/dev/null 2>&1 || true' EXIT INT TERM
fi

ENV=test PGDATABASE="$test_db" go test -p 1 -count=1 "$@" ./...
