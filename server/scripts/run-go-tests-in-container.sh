#!/bin/sh

set -eu

export PATH="/usr/local/go/bin:/go/bin:$PATH"

socat TCP-LISTEN:5432,fork,reuseaddr TCP:postgres-test:5432 &
socat_pid=$!

cleanup() {
    kill "$socat_pid" >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

until pg_isready -h localhost -p 5432 -U test_user -d ente_test_db >/dev/null 2>&1; do
    sleep 1
done

psql -h localhost -U test_user -d ente_test_db <<'SQL'
CREATE TABLE IF NOT EXISTS public.ente_test_db_sentinel (
    id integer PRIMARY KEY,
    marker text NOT NULL
);

INSERT INTO public.ente_test_db_sentinel (id, marker)
VALUES (1, 'ente-server-test-db-v1')
ON CONFLICT (id) DO UPDATE SET marker = EXCLUDED.marker;
SQL

exec go test -p 1 -count=1 "$@" ./...
