DROP TRIGGER IF EXISTS update_push_tokens_updated_at ON push_tokens;
DROP INDEX IF EXISTS push_tokens_last_notified_at_index;
DROP TABLE IF EXISTS push_tokens;
