ALTER TABLE temp_objects
    DROP COLUMN is_multipart,
    DROP COLUMN upload_id;

ALTER TABLE temp_objects  
    RENAME TO temp_object_keys;
