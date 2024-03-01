ALTER TYPE app ADD VALUE 'locker';

-- Alter the column to make it non-null

ALTER TABLE collections ADD COLUMN app app DEFAULT 'photos';

-- Update the existing app that are null to default ("photos") and make it non null.

UPDATE collections SET app = 'photos' WHERE app IS NULL;

-- Alter the column to make it non-null

ALTER TABLE collections ALTER COLUMN app SET NOT NULL;

-- Create a new unique index for uncategorized collections

CREATE UNIQUE INDEX IF NOT EXISTS collections_uncategorized_constraint_index_v2 ON collections (owner_id, app)
WHERE (type = 'uncategorized');

-- Drop the older index if it exists

DROP INDEX IF EXISTS collections_uncategorized_constraint_index;