ALTER TABLE collection_shares
    ADD COLUMN IF NOT EXISTS shared_at BIGINT;
