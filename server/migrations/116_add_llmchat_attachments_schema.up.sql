CREATE TABLE IF NOT EXISTS llmchat_attachments (
    id             BIGSERIAL PRIMARY KEY,
    attachment_id  uuid   NOT NULL,
    user_id        BIGINT NOT NULL,
    message_uuid   uuid   NOT NULL,
    size           BIGINT NOT NULL,
    encrypted_name TEXT   NOT NULL,
    created_at     BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
    CONSTRAINT fk_llmchat_attachments_user_id FOREIGN KEY (user_id) REFERENCES llmchat_key (user_id) ON DELETE CASCADE,
    CONSTRAINT fk_llmchat_attachments_message_uuid FOREIGN KEY (message_uuid) REFERENCES llmchat_messages (message_uuid) ON DELETE CASCADE,
    CONSTRAINT llmchat_attachments_size_constraint CHECK (size >= 0),
    CONSTRAINT llmchat_attachments_unique_per_user UNIQUE (user_id, attachment_id)
);

CREATE INDEX IF NOT EXISTS llmchat_attachments_user_message_index
    ON llmchat_attachments (user_id, message_uuid);

CREATE INDEX IF NOT EXISTS llmchat_attachments_user_attachment_index
    ON llmchat_attachments (user_id, attachment_id);
