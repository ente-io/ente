ALTER TABLE users 
    ADD COLUMN encrypted_email BYTEA,
    ADD COLUMN email_decryption_nonce BYTEA,
    ADD COLUMN email_hash TEXT UNIQUE;

CREATE INDEX IF NOT EXISTS users_email_hash_index ON users(email_hash);

ALTER TABLE users ALTER COLUMN email DROP NOT NULL;

ALTER TABLE otts
    ADD COLUMN email_hash TEXT;

ALTER TABLE otts ALTER COLUMN email DROP NOT NULL;

CREATE INDEX IF NOT EXISTS otts_email_hash_index ON otts(email_hash);
