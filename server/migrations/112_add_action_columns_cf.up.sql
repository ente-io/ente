-- Add action markers to collection_files to drive client behavior during diffs
-- action_user: user who initiated the action
-- action: opaque text value, initially expected to be 'REMOVE' or 'DELETE'
ALTER TABLE collection_files
    ADD COLUMN IF NOT EXISTS action_user bigint,
    ADD COLUMN IF NOT EXISTS action text;

