-- Add types for the new dcs that are introduced for the derived data

ALTER TABLE passkey_login_sessions
    DROP COLUMN IF EXISTS token_fetch_cnt,
    DROP COLUMN IF EXISTS verified_at,
    DROP COLUMN IF EXISTS token_data;
