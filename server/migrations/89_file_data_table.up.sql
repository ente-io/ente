ALTER TYPE OBJECT_TYPE ADD VALUE 'derivedMeta';
ALTER TYPE s3region ADD VALUE 'b5';
-- Create the derived table
CREATE TABLE IF NOT EXISTS file_data
(
    file_id             BIGINT      NOT NULL,
    user_id             BIGINT      NOT NULL,
    data_type           OBJECT_TYPE NOT NULL,
    size                BIGINT      NOT NULL,
    latest_bucket       s3region    NOT NULL,
    replicated_buckets  s3region[]  NOT NULL DEFAULT '{}',
--  following field contains list of buckets from where we need to delete the data as the given data_type will not longer be persisted in that dc
    delete_from_buckets s3region[]  NOT NULL DEFAULT '{}',
    pending_sync        BOOLEAN     NOT NULL DEFAULT false,
    is_deleted          BOOLEAN     NOT NULL DEFAULT false,
    last_sync_time      BIGINT      NOT NULL DEFAULT 0,
    created_at          BIGINT      NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at          BIGINT      NOT NULL DEFAULT now_utc_micro_seconds(),
    PRIMARY KEY (file_id, data_type)
);


-- Add index for user_id and data_type for efficient querying
CREATE INDEX idx_file_data_user_type_deleted ON file_data (user_id, data_type, is_deleted) INCLUDE (file_id, size);

CREATE OR REPLACE FUNCTION ensure_no_common_entries()
    RETURNS TRIGGER AS $$
BEGIN
    -- Check for common entries between latest_bucket and replicated_buckets
    IF NEW.latest_bucket = ANY(NEW.replicated_buckets) THEN
        RAISE EXCEPTION 'latest_bucket and replicated_buckets have common entries';
    END IF;

    -- Check for common entries between latest_bucket and delete_from_buckets
    IF NEW.latest_bucket = ANY(NEW.delete_from_buckets) THEN
        RAISE EXCEPTION 'latest_bucket and delete_from_buckets have common entries';
    END IF;

    -- Check for common entries between replicated_buckets and delete_from_buckets
    IF EXISTS (
            SELECT 1 FROM unnest(NEW.replicated_buckets) AS rb
            WHERE rb = ANY(NEW.delete_from_buckets)
        ) THEN
        RAISE EXCEPTION 'replicated_buckets and delete_from_buckets have common entries';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_no_common_entries
    BEFORE INSERT OR UPDATE ON file_data
    FOR EACH ROW EXECUTE FUNCTION ensure_no_common_entries();

