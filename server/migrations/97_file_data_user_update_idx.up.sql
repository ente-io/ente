CREATE INDEX CONCURRENTLY idx_file_data_user_updated
    ON file_data (user_id, updated_at);
