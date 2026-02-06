DROP TRIGGER IF EXISTS trigger_llmchat_key_on_messages_updation ON llmchat_messages;
DROP TRIGGER IF EXISTS trigger_llmchat_key_on_sessions_updation ON llmchat_sessions;
DROP TRIGGER IF EXISTS update_llmchat_messages_updated_at ON llmchat_messages;
DROP TRIGGER IF EXISTS update_llmchat_sessions_updated_at ON llmchat_sessions;

DROP FUNCTION IF EXISTS fn_update_llmchat_key_updated_at_via_updated_at();

DROP INDEX IF EXISTS llmchat_attachments_user_attachment_index;
DROP INDEX IF EXISTS llmchat_attachments_user_message_index;
DROP INDEX IF EXISTS llmchat_messages_state_updated_at_index;
DROP INDEX IF EXISTS llmchat_sessions_state_updated_at_index;

DROP TABLE IF EXISTS llmchat_attachments;
DROP TABLE IF EXISTS llmchat_messages;
DROP TABLE IF EXISTS llmchat_sessions;
DROP TABLE IF EXISTS llmchat_key;
