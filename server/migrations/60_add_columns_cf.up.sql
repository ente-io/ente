ALTER TABLE collection_files
    ADD COLUMN IF NOT EXISTS c_owner_id bigint,
    ADD COLUMN IF NOT EXISTS f_owner_id bigint,
    ADD COLUMN IF NOT EXISTS created_at bigint;
-- set default after adding a colum otherwise for all existing rows we will end up setting wrong created_at time
ALTER TABLE collection_files
    ALTER created_at SET DEFAULT now_utc_micro_seconds();

CREATE TYPE role_enum AS ENUM ('VIEWER', 'COLLABORATOR', 'OWNER');

ALTER TABLE collection_shares
    ADD COLUMN IF NOT EXISTS role_type role_enum DEFAULT 'VIEWER';
