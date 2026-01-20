ALTER TABLE llmchat_messages
    ADD COLUMN IF NOT EXISTS attachments JSONB NOT NULL DEFAULT '[]'::jsonb;

UPDATE llmchat_messages m
SET attachments = COALESCE(
    (
        SELECT jsonb_agg(
            jsonb_build_object(
                'id', a.attachment_id::text,
                'size', a.size,
                'encrypted_name', a.encrypted_name
            )
            ORDER BY a.id
        )
        FROM llmchat_attachments a
        WHERE a.message_uuid = m.message_uuid AND a.user_id = m.user_id
    ),
    '[]'::jsonb
);

CREATE INDEX IF NOT EXISTS llmchat_messages_attachments_gin_index
    ON llmchat_messages USING GIN (attachments);

DROP TRIGGER IF EXISTS update_llmchat_attachments_updated_at ON llmchat_attachments;

DROP INDEX IF EXISTS llmchat_attachments_user_message_index;
DROP INDEX IF EXISTS llmchat_attachments_user_attachment_index;

DROP TABLE IF EXISTS llmchat_attachments;
