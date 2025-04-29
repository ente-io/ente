ALTER TABLE temp_object_keys  
    RENAME TO temp_objects;

ALTER TABLE temp_objects
    ADD COLUMN is_multipart  BOOLEAN,
    ADD COLUMN upload_id TEXT;

UPDATE temp_objects SET is_multipart ='f';

ALTER TABLE temp_objects 
    ALTER COLUMN is_multipart SET NOT NULL,
    ALTER COLUMN is_multipart SET DEFAULT FALSE;
    