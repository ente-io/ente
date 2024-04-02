ALTER TYPE model ADD VALUE IF NOT EXISTS 'file-ml-clip-face';
ALTER TABLE embeddings
    ADD COLUMN size int DEFAULT NULL,
    ADD COLUMN version int DEFAULT 1;
