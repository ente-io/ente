BEGIN;
ALTER table public_collection_tokens
    DROP COLUMN IF EXISTS pw_hash,
    DROP COLUMN IF EXISTS pw_nonce,
    DROP COLUMN IF EXISTS mem_limit,
    DROP COLUMN IF EXISTS ops_limit,
    DROP COLUMN IF EXISTS enable_download,
    DROP COLUMN IF EXISTS enable_comment;


ALTER TABLE public_collection_tokens
    DROP CONSTRAINT IF EXISTS pct_pw_state_constraint;
COMMIT;
