ALTER TABLE collections
    DROP COLUMN encrypted_name
    DROP COLUMN name_decryption_nonce
    ALTER COLUMN name SET NOT NULL;
