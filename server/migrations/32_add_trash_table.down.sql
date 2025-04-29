DROP TRIGGER IF EXISTS update_trash_updated_at ON trash;
ALTER TABLE trash DROP CONSTRAINT IF EXISTS trash_state_constraint;
DROP INDEX trash_updated_at_time_index;
DROP TABLE IF EXISTS trash;
