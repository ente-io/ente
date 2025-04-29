-- Add columns to passkey_login_sessions table for facilitating token fetch in case of passkey redirect
-- not working.
ALTER TABLE passkey_login_sessions
    ADD COLUMN IF NOT EXISTS token_fetch_cnt int default 0,
    ADD COLUMN IF NOT EXISTS verified_at BIGINT,
    ADD COLUMN IF NOT EXISTS token_data jsonb;
