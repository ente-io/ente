-- DELETE source column if exists
ALTER TABLE users
    DROP COLUMN IF EXISTS source;
-- DELETE delete_feedback column if exists
ALTER TABLE users
    DROP COLUMN IF EXISTS delete_feedback;
