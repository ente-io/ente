CREATE TABLE IF NOT EXISTS usage(
    user_id INTEGER NOT NULL,
    storage_consumed BIGINT NOT NULL,

    CONSTRAINT fk_usage_user_id
        FOREIGN KEY(user_id)
            REFERENCES users(user_id)
            ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS usage_user_id_index ON usage(user_id);

INSERT INTO usage(user_id,storage_consumed)
    SELECT user_id, COALESCE(total_file_size+total_thumbnail_size,0) FROM 
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
