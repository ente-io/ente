#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
server_dir="$(cd "${script_dir}/.." && pwd)"

cd "${server_dir}"

psql_base_args=(-v ON_ERROR_STOP=1)

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
SQL
