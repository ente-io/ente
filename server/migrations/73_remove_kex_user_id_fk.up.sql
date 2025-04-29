ALTER TABLE kex_store DROP CONSTRAINT IF EXISTS fk_kex_store_user_id;

ALTER TABLE kex_store DROP COLUMN IF EXISTS user_id;