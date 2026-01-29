-- Memory share table - stores shared memory metadata
CREATE TABLE IF NOT EXISTS memory_shares (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id),
    type TEXT NOT NULL CHECK (type IN ('share', 'lane')),
    metadata_cipher TEXT,
    metadata_nonce TEXT,
    mem_enc_key TEXT NOT NULL,
    mem_key_decryption_nonce TEXT NOT NULL,
    access_token TEXT NOT NULL UNIQUE,
    is_deleted BOOLEAN DEFAULT false,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_memory_shares_user_id ON memory_shares(user_id);
CREATE INDEX IF NOT EXISTS idx_memory_shares_access_token ON memory_shares(access_token);

-- Memory share files - tracks files in each memory share with their owners
CREATE TABLE IF NOT EXISTS memory_share_files (
    id BIGSERIAL PRIMARY KEY,
    memory_share_id BIGINT NOT NULL REFERENCES memory_shares(id) ON DELETE CASCADE,
    file_id BIGINT NOT NULL,
    file_owner_id BIGINT NOT NULL,
    file_enc_key TEXT NOT NULL,
    file_key_decryption_nonce TEXT NOT NULL,
    created_at BIGINT NOT NULL,
    UNIQUE(memory_share_id, file_id)
);

CREATE INDEX IF NOT EXISTS idx_memory_share_files_share_id ON memory_share_files(memory_share_id);
CREATE INDEX IF NOT EXISTS idx_memory_share_files_file_id ON memory_share_files(file_id);
