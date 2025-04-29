CREATE TYPE s3region AS ENUM ('b2-eu-cen','scw-eu-fr');

ALTER TABLE thumbnail_object_keys
    ADD COLUMN datacenters s3region[] DEFAULT '{}';

UPDATE thumbnail_object_keys SET datacenters = '{b2-eu-cen}';

ALTER TABLE file_object_keys
    ADD COLUMN datacenters s3region[] DEFAULT '{}';

UPDATE file_object_keys SET datacenters = '{b2-eu-cen}';

CREATE TABLE IF NOT EXISTS task_lock (
    task_name TEXT PRIMARY KEY,
    lock_until BIGINT NOT NULL,
    locked_at BIGINT NOT NULL,
    locked_by TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS task_lock_locked_until ON task_lock(lock_until);

CREATE TABLE IF NOT EXISTS queue (
    queue_id SERIAL PRIMARY KEY,
    queue_name TEXT NOT NULL,
    item TEXT NOT NULL
);
