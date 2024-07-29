-- Create the data_type enum
CREATE TYPE derived_data_type AS ENUM ('img_jpg_preview', 'vid_hls_preview', 'meta');

-- Create the derived table
CREATE TABLE derived (
                         file_id BIGINT NOT NULL,
                         user_id BIGINT NOT NULL,
                         data_type derived_data_type NOT NULL,
                         size BIGINT NOT NULL,
                         latest_bucket s3region NOT NULL,
                         replicated_buckets s3region[] NOT NULL,
--                       following field contains list of buckets from where we need to delete the data as the given data_type will not longer be persisted in that dc
                         delete_from_buckets s3region[] NOT NULL DEFAULT '{}',
                         pending_sync BOOLEAN NOT NULL DEFAULT false,
                         created_at BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
                         updated_at BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
                         PRIMARY KEY (file_id, data_type)
);

-- Add primary key
ALTER TABLE derived ADD PRIMARY KEY (file_id, data_type);

-- Add index for user_id and data_type
CREATE INDEX idx_derived_user_id_data_type ON derived (user_id, data_type);

-- Add index for user_id and updated_at for efficient querying
CREATE INDEX idx_derived_user_id_updated_at ON derived (user_id, updated_at);