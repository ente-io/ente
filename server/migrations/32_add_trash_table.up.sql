CREATE TABLE IF NOT EXISTS trash
(
    file_id       BIGINT NOT NULL,
    user_id       BIGINT NOT NULL,
    collection_id BIGINT NOT NULL,
    --  is_deleted true indicates file has been deleted and cannot be restored.
    is_deleted    bool   NOT NULL DEFAULT false,
    --  true indicates file was moved to trash but user restored it before deletion.
    is_restored   bool   NOT NULL default false,
    created_at    bigint NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at    bigint NOT NULL DEFAULT now_utc_micro_seconds(),
    delete_by     bigint NOT NULL,
    PRIMARY KEY (file_id),
    CONSTRAINT fk_trash_keys_collection_files
        FOREIGN KEY (file_id, collection_id)
            REFERENCES collection_files (file_id, collection_id)
            ON DELETE NO ACTION
);

CREATE INDEX IF NOT EXISTS trash_updated_at_time_index ON trash (updated_at);

ALTER TABLE trash
    ADD CONSTRAINT trash_state_constraint CHECK (is_deleted is FALSE or is_restored is FALSE);

CREATE TRIGGER update_trash_updated_at
    BEFORE UPDATE
    ON trash
    FOR EACH ROW
EXECUTE PROCEDURE
    trigger_updated_at_microseconds_column();
