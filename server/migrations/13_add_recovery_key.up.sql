ALTER TABLE key_attributes 
    ADD COLUMN master_key_encrypted_with_recovery_key TEXT,
    ADD COLUMN master_key_decryption_nonce TEXT,
    ADD COLUMN recovery_key_encrypted_with_master_key TEXT,
    ADD COLUMN recovery_key_decryption_nonce TEXT;
