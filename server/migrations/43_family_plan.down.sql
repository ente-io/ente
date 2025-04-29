ALTER TABLE users
    DROP COLUMN family_admin_id;
DROP TRIGGER IF EXISTS update_families_updated_at ON families;
DROP INDEX IF EXISTS fk_families_admin_id;
DROP INDEX IF EXISTS uidx_one_family_check;
DROP INDEX IF EXISTS uidx_families_member_mapping;
DROP TABLE families;
