ALTER TABLE public_file_tokens
    ADD COLUMN IF NOT EXISTS encrypted_file_key TEXT,
    ADD COLUMN IF NOT EXISTS encrypted_file_key_nonce TEXT,
    ADD COLUMN IF NOT EXISTS kdf_nonce TEXT,
    ADD COLUMN IF NOT EXISTS kdf_mem_limit BIGINT,
    ADD COLUMN IF NOT EXISTS kdf_ops_limit BIGINT,
    ADD COLUMN IF NOT EXISTS encrypted_share_key TEXT;
