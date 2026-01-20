CREATE TABLE IF NOT EXISTS llmchat_attachments (
    id             BIGSERIAL PRIMARY KEY,
    attachment_id  uuid   NOT NULL,
    user_id        BIGINT NOT NULL,
    message_uuid   uuid   NOT NULL,
    size           BIGINT NOT NULL,
    encrypted_name TEXT   NOT NULL,
    created_at     BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at     BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
    CONSTRAINT fk_llmchat_attachments_user_id FOREIGN KEY (user_id) REFERENCES llmchat_key (user_id) ON DELETE CASCADE,
    CONSTRAINT fk_llmchat_attachments_message_uuid FOREIGN KEY (message_uuid) REFERENCES llmchat_messages (message_uuid) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS llmchat_attachments_user_attachment_index
    ON llmchat_attachments (user_id, attachment_id);

CREATE INDEX IF NOT EXISTS llmchat_attachments_user_message_index
    ON llmchat_attachments (user_id, message_uuid);

CREATE TRIGGER update_llmchat_attachments_updated_at
    BEFORE UPDATE
    ON llmchat_attachments
    FOR EACH ROW
EXECUTE PROCEDURE trigger_updated_at_microseconds_column();

INSERT INTO llmchat_attachments (
    attachment_id,
    user_id,
    message_uuid,
    size,
    encrypted_name,
    created_at,
    updated_at
)
SELECT
    (attachment->>'id')::uuid,
    m.user_id,
    m.message_uuid,
    COALESCE((attachment->>'size')::bigint, 0),
    COALESCE(attachment->>'encrypted_name', ''),
    m.created_at,
    m.updated_at
FROM llmchat_messages m
JOIN LATERAL jsonb_array_elements(m.attachments) attachment ON TRUE
WHERE m.attachments IS NOT NULL AND jsonb_array_length(m.attachments) > 0;

DROP INDEX IF EXISTS llmchat_messages_attachments_gin_index;
ALTER TABLE llmchat_messages DROP COLUMN IF EXISTS attachments;
