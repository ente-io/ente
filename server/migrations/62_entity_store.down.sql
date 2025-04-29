DROP TRIGGER IF EXISTS update_entity_data_updated_at ON entity_data;
DROP INDEX IF EXISTS entity_data_updated_at_time_index;
DROP INDEX IF EXISTS entity_data_state_constraint;
DROP TRIGGER IF EXISTS trigger_entity_key_on_entity_data_updation on entity_data;
DROP TABLE IF EXISTS entity_data;
DROP TABLE IF EXISTS entity_key;
