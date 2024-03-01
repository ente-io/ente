DROP TRIGGER IF EXISTS update_embeddings_updated_at ON embeddings;
DROP TABLE embeddings;
DROP TYPE  model;
DROP INDEX IF EXISTS embeddings_owner_id_updated_at_index;
