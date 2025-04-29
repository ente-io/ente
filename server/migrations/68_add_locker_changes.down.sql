-- Drop the new unique index

DROP INDEX IF EXISTS collections_uncategorized_constraint_index_v2;

-- Re-create the old unique index

CREATE UNIQUE INDEX IF NOT EXISTS collections_uncategorized_constraint_index ON collections (owner_id, app)
WHERE (type = 'uncategorized');

-- Remove NOT NULL constraints

ALTER TABLE collections ALTER COLUMN app DROP NOT NULL;

-- Remove default values

ALTER TABLE collections ALTER COLUMN app DROP DEFAULT;

-- Update columns back to NULL

UPDATE collections SET app = NULL WHERE app = 'photos';
