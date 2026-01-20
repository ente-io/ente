ALTER TABLE llmchat_messages
    DROP CONSTRAINT IF EXISTS fk_llmchat_messages_session_uuid;
