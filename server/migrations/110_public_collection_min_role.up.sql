ALTER TABLE public_collection_tokens
    ADD COLUMN IF NOT EXISTS min_role role_enum;
