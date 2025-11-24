-- Make favorites unique per (owner_id, app), similar to uncategorized

CREATE UNIQUE INDEX IF NOT EXISTS collections_favorites_constraint_index_v2 ON collections (owner_id, app)
WHERE (type = 'favorites');

-- Drop the older index if it exists

DROP INDEX IF EXISTS collections_favorites_constraint_index;

