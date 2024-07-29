-- Create the data_type enum
CREATE TYPE file_data_type AS ENUM ('img_jpg_preview', 'vid_hls_preview', 'derived');

-- Create the derived table
CREATE TABLE file_data (
                         file_id BIGINT NOT NULL,
                         user_id BIGINT NOT NULL,
                         data_type file_data_type NOT NULL,
                         size BIGINT NOT NULL,
                         latest_bucket s3region NOT NULL,
                         replicated_buckets s3region[] NOT NULL,
--                       following field contains list of buckets from where we need to delete the data as the given data_type will not longer be persisted in that dc
                         delete_from_buckets s3region[] NOT NULL DEFAULT '{}',
                         pending_sync BOOLEAN NOT NULL DEFAULT false,
                         last_sync_time BIGINT NOT NULL DEFAULT 0,
                         created_at BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
                         updated_at BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
                         PRIMARY KEY (file_id, data_type)
);

-- Add primary key
ALTER TABLE file_data ADD PRIMARY KEY (file_id, data_type);

-- Add index for user_id and data_type
CREATE INDEX idx_file_data_user_id_data_type ON file_data (user_id, data_type);

-- Add index for user_id and updated_at for efficient querying
CREATE INDEX idx_file_data_user_id_updated_at ON file_data (user_id, updated_at);