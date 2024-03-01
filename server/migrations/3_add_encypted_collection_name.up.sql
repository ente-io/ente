ALTER TABLE collections
    ADD COLUMN encrypted_name TEXT,
    ADD COLUMN name_decryption_nonce TEXT,
    ALTER COLUMN name DROP NOT NULL;
