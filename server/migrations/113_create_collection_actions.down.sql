DROP TRIGGER IF EXISTS update_collection_actions_updated_at ON collection_actions;
DROP INDEX IF EXISTS collection_actions_user_id_idx;
DROP INDEX IF EXISTS collection_actions_collection_id_idx;
DROP INDEX IF EXISTS collection_actions_pending_remove_delete_user_time_idx;
DROP TABLE IF EXISTS collection_actions;
