ALTER TABLE llmchat_messages
    ADD CONSTRAINT fk_llmchat_messages_session_uuid
    FOREIGN KEY (session_uuid) REFERENCES llmchat_sessions (session_uuid);
