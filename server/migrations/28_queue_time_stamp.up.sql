ALTER TABLE queue
    ADD COLUMN created_at bigint DEFAULT now_utc_micro_seconds(),
    ADD COLUMN updated_at bigint DEFAULT now_utc_micro_seconds(),
    ADD COLUMN is_deleted bool   DEFAULT false;

CREATE UNIQUE INDEX IF NOT EXISTS name_and_item_unique_index ON queue (queue_name, item);
CREATE INDEX IF NOT EXISTS q_name_create_and_is_deleted_index on queue (queue_name, created_at, is_deleted);

CREATE TRIGGER update_queue_updated_at
    BEFORE UPDATE
    ON queue
    FOR EACH ROW
EXECUTE PROCEDURE
    trigger_updated_at_microseconds_column();
