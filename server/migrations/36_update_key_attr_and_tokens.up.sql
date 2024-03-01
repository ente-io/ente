BEGIN;
ALTER TABLE key_attributes
    ADD COLUMN IF NOT EXISTS created_at bigint DEFAULT now_utc_micro_seconds();
UPDATE key_attributes k
SET created_at = u.creation_time
FROM users u
where k.user_id = u.user_id;

ALTER TABLE key_attributes
    ALTER COLUMN created_at SET NOT NULL;
COMMIT;

BEGIN;
ALTER table tokens
    ADD COLUMN IF NOT EXISTS is_deleted   bool   DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS last_used_at bigint DEFAULT now_utc_micro_seconds();

UPDATE tokens
SET last_used_at = creation_time,
    is_deleted   = FALSE;

ALTER TABLE tokens
    ALTER COLUMN is_deleted SET NOT NULL,
    ALTER COLUMN last_used_at SET NOT NULL;
COMMIT;
