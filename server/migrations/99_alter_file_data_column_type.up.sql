ALTER TABLE file_data
    ALTER COLUMN obj_size TYPE bigint USING obj_size::bigint;