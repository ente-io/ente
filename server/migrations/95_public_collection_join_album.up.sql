BEGIN;
ALTER table public_collection_tokens
    ADD COLUMN IF NOT EXISTS enable_join  bool DEFAULT TRUE;

UPDATE public_collection_tokens SET enable_join = FALSE;

ALTER TABLE public_collection_tokens ALTER COLUMN enable_join SET NOT NULL;

COMMIT;
