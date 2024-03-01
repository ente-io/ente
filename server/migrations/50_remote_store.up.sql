CREATE TABLE IF NOT EXISTS remote_store
(
    user_id    BIGINT         NOT NULL,
    key_name   TEXT           NOT NULL,
    key_value  TEXT           NOT NULL,
    created_at bigint         NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at bigint         NOT NULL DEFAULT now_utc_micro_seconds(),
    PRIMARY KEY (user_id, key_name),
    CONSTRAINT fk_remote_store_user_id
        FOREIGN KEY (user_id)
            REFERENCES users (user_id)
            ON DELETE CASCADE
);


CREATE TRIGGER update_remote_store_updated_at
    BEFORE UPDATE
    ON remote_store
    FOR EACH ROW
EXECUTE PROCEDURE
    trigger_updated_at_microseconds_column();

