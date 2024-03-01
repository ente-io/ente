ALTER TABLE queue
    DROP COLUMN created_at,
    DROP COLUMN updated_at,
    DROP COLUMN is_deleted;
DROP INDEX IF EXISTS name_and_item_unique_index;
DROP INDEX IF EXISTS q_name_create_and_is_deleted_index;

DROP TRIGGER IF EXISTS update_queue_updated_at ON queue;
