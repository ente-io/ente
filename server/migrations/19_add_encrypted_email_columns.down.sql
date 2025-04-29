ALTER TABLE users 
    DROP COLUMN encrypted_email,
    DROP COLUMN email_decryption_nonce,
    DROP COLUMN email_hash;

DROP INDEX users_email_hash_index;

ALTER TABLE users ALTER COLUMN email SET NOT NULL;

ALTER TABLE otts DROP COLUMN email_hash;

ALTER TABLE otts ALTER COLUMN email SET NOT NULL;

DROP INDEX otts_email_hash_index;
