ALTER TABLE key_attributes
    DROP COLUMN master_key_encrypted_with_recovery_key,
    DROP COLUMN master_key_decryption_nonce,
    DROP COLUMN recovery_key_encrypted_with_master_key,
    DROP COLUMN recovery_key_decryption_nonce;
