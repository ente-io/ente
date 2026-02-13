ALTER TABLE collections
    ADD COLUMN IF NOT EXISTS enable_comment_and_reactions BOOLEAN NOT NULL DEFAULT TRUE;
