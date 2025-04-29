BEGIN;
ALTER TABLE entity_data ADD COLUMN id_uuid UUID;
UPDATE entity_data SET id_uuid = id::UUID;
ALTER TABLE entity_data ALTER COLUMN id_uuid SET NOT NULL;
ALTER TABLE entity_data DROP CONSTRAINT entity_data_pkey;
ALTER TABLE entity_data DROP COLUMN IF EXISTS id;
ALTER TABLE entity_data RENAME COLUMN id_uuid TO id;
ALTER TABLE entity_data ADD PRIMARY KEY (id);
COMMIT;
