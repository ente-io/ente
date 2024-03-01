ALTER TABLE collection_files
    DROP COLUMN IF EXISTS c_owner_id,
    DROP COLUMN IF EXISTS f_owner_id,
    DROP COLUMN IF EXISTS created_at;

ALTER TABLE collection_shares DROP COLUMN IF EXISTS role_type;

DROP TYPE IF EXISTS role_enum;
