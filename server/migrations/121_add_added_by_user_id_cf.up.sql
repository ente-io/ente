-- Track who actually added each row in collection_files. NULL means
-- "added by collection owner" (legacy rows). For collaborator-uploaded
-- files this records the collaborator's user_id while file.owner_id stays
-- with the album owner.
ALTER TABLE collection_files
    ADD COLUMN IF NOT EXISTS added_by_user_id BIGINT;
