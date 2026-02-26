ALTER TABLE public_file_tokens
    DROP COLUMN IF EXISTS encrypted_file_key,
    DROP COLUMN IF EXISTS encrypted_file_key_nonce,
    DROP COLUMN IF EXISTS kdf_nonce,
    DROP COLUMN IF EXISTS kdf_mem_limit,
    DROP COLUMN IF EXISTS kdf_ops_limit,
    DROP COLUMN IF EXISTS encrypted_share_key;
