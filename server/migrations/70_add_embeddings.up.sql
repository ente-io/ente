CREATE TYPE model AS ENUM ('ggml-clip');

CREATE TABLE IF NOT EXISTS embeddings(
    file_id BIGINT NOT NULL,
    owner_id BIGINT NOT NULL,
    model model NOT NULL,
    encrypted_embedding TEXT NOT NULL,
    decryption_header TEXT NOT NULL,
    updated_at BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
    CONSTRAINT unique_embeddings_file_id_model
        UNIQUE (file_id, model),
    CONSTRAINT fk_embeddings_file_id
        FOREIGN KEY (file_id)
            REFERENCES files (file_id)
            ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS embeddings_owner_id_updated_at_index ON embeddings (owner_id, updated_at);

CREATE TRIGGER update_embeddings_updated_at
    BEFORE UPDATE
    ON embeddings
    FOR EACH ROW
EXECUTE PROCEDURE
    trigger_updated_at_microseconds_column();
