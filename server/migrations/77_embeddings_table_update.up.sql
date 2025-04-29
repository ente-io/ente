ALTER TABLE embeddings
 ALTER COLUMN encrypted_embedding DROP NOT NULL,
 ALTER COLUMN decryption_header DROP NOT NULL;
