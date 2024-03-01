ALTER TABLE key_attributes
    DROP COLUMN created_at;

ALTER TABLE tokens
    DROP COLUMN is_deleted;
ALTER TABLE tokens
    DROP COLUMN last_used_at;
