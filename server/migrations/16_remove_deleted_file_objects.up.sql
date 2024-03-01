DELETE FROM file_object_keys
WHERE file_id NOT IN (
    SELECT DISTINCT file_id FROM collection_files 
    WHERE is_deleted=false
    );

DELETE FROM thumbnail_object_keys
WHERE file_id NOT IN (
    SELECT DISTINCT file_id FROM collection_files 
    WHERE is_deleted=false
);
