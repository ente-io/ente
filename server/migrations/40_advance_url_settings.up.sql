BEGIN;
ALTER table public_collection_tokens
    ADD COLUMN IF NOT EXISTS pw_hash         TEXT,
    ADD COLUMN IF NOT EXISTS pw_nonce        TEXT,
    ADD COLUMN IF NOT EXISTS mem_limit       BIGINT,
    ADD COLUMN IF NOT EXISTS ops_limit       BIGINT,
    ADD COLUMN IF NOT EXISTS enable_download bool DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS enable_comment  bool DEFAULT FALSE;

UPDATE public_collection_tokens
SET enable_download = TRUE,
    enable_comment  = FALSE;

ALTER TABLE public_collection_tokens
    ALTER COLUMN enable_download SET NOT NULL,
    ALTER COLUMN enable_comment SET NOT NULL;

ALTER TABLE public_collection_tokens
    ADD CONSTRAINT pct_pw_state_constraint CHECK ( (pw_hash is NULL and pw_nonce is NULL) or
                                                   (pw_hash is NOT NULL and pw_nonce is NOT NULL));
COMMIT;
