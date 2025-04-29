ALTER TABLE embeddings
 ALTER COLUMN encrypted_embedding SET NOT NULL,
 ALTER COLUMN decryption_header SET NOT NULL;
