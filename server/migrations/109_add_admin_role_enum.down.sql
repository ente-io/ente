-- Remove ADMIN role from collection share role enum by recreating the type.
-- Any existing ADMIN entries are downgraded to COLLABORATOR before the type change.
UPDATE collection_shares
SET role_type = 'COLLABORATOR'
WHERE role_type = 'ADMIN';

ALTER TABLE collection_shares ALTER COLUMN role_type DROP DEFAULT;
ALTER TABLE collection_shares ALTER COLUMN role_type TYPE TEXT;

DROP TYPE IF EXISTS role_enum;
CREATE TYPE role_enum AS ENUM ('VIEWER', 'COLLABORATOR', 'OWNER');

ALTER TABLE collection_shares
    ALTER COLUMN role_type TYPE role_enum USING role_type::role_enum,
    ALTER COLUMN role_type SET DEFAULT 'VIEWER';
