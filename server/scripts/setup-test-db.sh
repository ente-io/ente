#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
server_dir="$(cd "${script_dir}/.." && pwd)"

cd "${server_dir}"

if [[ -n "${DATABASE_URL:-}" || -n "${PGSERVICE:-}" || -n "${PGSERVICEFILE:-}" ]]; then
    echo "Refusing to run setup-test-db.sh with DATABASE_URL/PGSERVICE/PGSERVICEFILE set." >&2
    echo "These can redirect psql to a non-local database cluster." >&2
    exit 1
fi

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

if [[ "${ALLOW_NONLOCAL_TEST_DB_SETUP:-0}" != "1" ]]; then
    if ! is_local_target "${PGHOST:-}"; then
        echo "Refusing to run setup-test-db.sh against non-local PGHOST=${PGHOST}." >&2
        echo "Set ALLOW_NONLOCAL_TEST_DB_SETUP=1 only if you are intentionally targeting a safe non-production cluster." >&2
        exit 1
    fi
    if ! is_local_target "${PGHOSTADDR:-}"; then
        echo "Refusing to run setup-test-db.sh against non-local PGHOSTADDR=${PGHOSTADDR}." >&2
        echo "Set ALLOW_NONLOCAL_TEST_DB_SETUP=1 only if you are intentionally targeting a safe non-production cluster." >&2
        exit 1
    fi
fi

psql_base_args=(-v ON_ERROR_STOP=1)
sentinel_table="ente_test_db_sentinel"
sentinel_marker="ente-server-test-db-v1"

db_exists="$(psql "${psql_base_args[@]}" -d postgres -Atqc "SELECT 1 FROM pg_database WHERE datname = 'ente_test_db'")"
if [[ "${db_exists}" == "1" ]]; then
    existing_marker="$(psql "${psql_base_args[@]}" -d ente_test_db -Atqc "SELECT marker FROM public.${sentinel_table} WHERE id = 1" 2>/dev/null || true)"
    if [[ -z "${existing_marker}" && "${ALLOW_UNMARKED_EXISTING_TEST_DB:-0}" != "1" ]]; then
        echo "Refusing to operate on existing ente_test_db without the expected test sentinel." >&2
        echo "If this is your known local test DB and you want to bootstrap the sentinel once, rerun with ALLOW_UNMARKED_EXISTING_TEST_DB=1." >&2
        exit 1
    fi
    if [[ -n "${existing_marker}" && "${existing_marker}" != "${sentinel_marker}" ]]; then
        echo "Refusing to operate on ente_test_db with unexpected sentinel marker: ${existing_marker}" >&2
        exit 1
    fi
fi

psql "${psql_base_args[@]}" -d postgres <<'SQL'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'test_user') THEN
        CREATE ROLE test_user LOGIN PASSWORD 'test_pass';
    ELSE
        ALTER ROLE test_user WITH LOGIN PASSWORD 'test_pass';
    END IF;
END
$$;

SELECT 'CREATE DATABASE ente_test_db OWNER test_user'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'ente_test_db')\gexec

ALTER DATABASE ente_test_db OWNER TO test_user;
GRANT ALL PRIVILEGES ON DATABASE ente_test_db TO test_user;
SQL

psql "${psql_base_args[@]}" -d ente_test_db <<'SQL'
ALTER SCHEMA public OWNER TO test_user;
GRANT ALL PRIVILEGES ON SCHEMA public TO test_user;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO test_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO test_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO test_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO test_user;

CREATE TABLE IF NOT EXISTS public.ente_test_db_sentinel (
    id integer PRIMARY KEY,
    marker text NOT NULL
);

INSERT INTO public.ente_test_db_sentinel (id, marker)
VALUES (1, 'ente-server-test-db-v1')
ON CONFLICT (id) DO UPDATE SET marker = EXCLUDED.marker;
SQL
