INSERT INTO usage(user_id,storage_consumed)
    SELECT user_id, COALESCE(total_file_size+total_thumbnail_size,0) as storage_consumed FROM 
        users,
        LATERAL (
            SELECT SUM(size) AS total_thumbnail_size
            FROM thumbnail_object_keys
            LEFT JOIN files ON files.file_id = thumbnail_object_keys.file_id
            WHERE
                owner_id = users.user_id
        )  query_1,
        LATERAL (
            SELECT SUM(size) AS total_file_size
            FROM file_object_keys
            LEFT JOIN files ON files.file_id = file_object_keys.file_id
            WHERE
                owner_id = users.user_id 
        ) query_2
    ON CONFLICT (user_id) 
    DO UPDATE SET storage_consumed =EXCLUDED.storage_consumed;
