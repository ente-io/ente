ALTER TABLE users
    ADD COLUMN IF NOT EXISTS source text;
-- Add JSON column to capture delete feedback
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS delete_feedback jsonb;
