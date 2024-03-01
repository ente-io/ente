CREATE TABLE IF NOT EXISTS push_tokens
(
    user_id          BIGINT NOT NULL,
    fcm_token        TEXT   NOT NULL,
    apns_token       TEXT,
    created_at       bigint NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at       bigint NOT NULL DEFAULT now_utc_micro_seconds(),
    last_notified_at bigint NOT NULL DEFAULT now_utc_micro_seconds(),
    PRIMARY KEY (fcm_token),
    CONSTRAINT fk_push_tokens_user_id
        FOREIGN KEY (user_id)
            REFERENCES users (user_id)
            ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS push_tokens_last_notified_at_index ON push_tokens (last_notified_at);

CREATE TRIGGER update_push_tokens_updated_at
    BEFORE UPDATE
    ON push_tokens
    FOR EACH ROW
EXECUTE PROCEDURE
    trigger_updated_at_microseconds_column();
