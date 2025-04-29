BEGIN;
ALTER TABLE entity_data ADD COLUMN id_text TEXT;
UPDATE entity_data SET id_text = id::TEXT;
ALTER TABLE entity_data ALTER COLUMN id_text SET NOT NULL;
ALTER TABLE entity_data DROP CONSTRAINT entity_data_pkey;
ALTER TABLE entity_data DROP COLUMN IF EXISTS id;
ALTER TABLE entity_data RENAME COLUMN id_text TO id;
ALTER TABLE entity_data ADD PRIMARY KEY (id);
END;
