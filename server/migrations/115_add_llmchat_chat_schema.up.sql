-- LLMChat schema

CREATE TABLE IF NOT EXISTS llmchat_key (
    user_id       BIGINT PRIMARY KEY NOT NULL,
    encrypted_key TEXT   NOT NULL,
    header        TEXT   NOT NULL,
    created_at    BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at    BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
    CONSTRAINT fk_llmchat_key_user_id FOREIGN KEY (user_id) REFERENCES users (user_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS llmchat_sessions (
    session_uuid            uuid PRIMARY KEY NOT NULL,
    user_id                 BIGINT NOT NULL,
    root_session_uuid       uuid   NOT NULL,
    branch_from_message_uuid uuid,
    encrypted_data          TEXT,
    header                  TEXT,
    is_deleted              BOOLEAN NOT NULL DEFAULT FALSE,
    created_at              BIGINT  NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at              BIGINT  NOT NULL DEFAULT now_utc_micro_seconds(),
    CONSTRAINT fk_llmchat_sessions_user_id FOREIGN KEY (user_id) REFERENCES llmchat_key (user_id) ON DELETE CASCADE,
    CONSTRAINT llmchat_sessions_state_constraint CHECK (
        (is_deleted IS TRUE AND encrypted_data IS NULL AND header IS NULL) OR
        (is_deleted IS FALSE AND encrypted_data IS NOT NULL AND header IS NOT NULL)
    )
);

CREATE TABLE IF NOT EXISTS llmchat_messages (
    message_uuid        uuid PRIMARY KEY NOT NULL,
    user_id             BIGINT NOT NULL,
    session_uuid        uuid   NOT NULL,
    parent_message_uuid uuid,
    sender              TEXT   NOT NULL DEFAULT '',
    attachments         JSONB  NOT NULL DEFAULT '[]'::jsonb,
    encrypted_data      TEXT,
    header              TEXT,
    is_deleted          BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          BIGINT  NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at          BIGINT  NOT NULL DEFAULT now_utc_micro_seconds(),
    CONSTRAINT fk_llmchat_messages_user_id FOREIGN KEY (user_id) REFERENCES llmchat_key (user_id) ON DELETE CASCADE,
    CONSTRAINT llmchat_messages_state_constraint CHECK (
        (is_deleted IS TRUE AND encrypted_data IS NULL AND header IS NULL) OR
        (is_deleted IS FALSE AND encrypted_data IS NOT NULL AND header IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS llmchat_sessions_state_updated_at_index
    ON llmchat_sessions (user_id, is_deleted, updated_at);

CREATE INDEX IF NOT EXISTS llmchat_messages_state_updated_at_index
    ON llmchat_messages (user_id, is_deleted, updated_at);

CREATE INDEX IF NOT EXISTS llmchat_messages_attachments_gin_index
    ON llmchat_messages USING GIN (attachments);

CREATE TRIGGER update_llmchat_sessions_updated_at
    BEFORE UPDATE
    ON llmchat_sessions
    FOR EACH ROW
EXECUTE PROCEDURE trigger_updated_at_microseconds_column();

CREATE TRIGGER update_llmchat_messages_updated_at
    BEFORE UPDATE
    ON llmchat_messages
    FOR EACH ROW
EXECUTE PROCEDURE trigger_updated_at_microseconds_column();

-- Update llmchat_key.updated_at whenever a chat entry changes
CREATE OR REPLACE FUNCTION fn_update_llmchat_key_updated_at_via_updated_at() RETURNS TRIGGER AS
$$
BEGIN
    IF (TG_OP = 'UPDATE' OR TG_OP = 'INSERT') THEN
        UPDATE llmchat_key
        SET updated_at = NEW.updated_at
        WHERE user_id = NEW.user_id
          AND updated_at < NEW.updated_at;
        RETURN NEW;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_llmchat_key_on_sessions_updation
    AFTER INSERT OR UPDATE
    ON llmchat_sessions
    FOR EACH ROW
EXECUTE PROCEDURE fn_update_llmchat_key_updated_at_via_updated_at();

CREATE TRIGGER trigger_llmchat_key_on_messages_updation
    AFTER INSERT OR UPDATE
    ON llmchat_messages
    FOR EACH ROW
EXECUTE PROCEDURE fn_update_llmchat_key_updated_at_via_updated_at();
