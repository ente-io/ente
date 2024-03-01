-- Migration script for collections with bad type due to bug on mobile client & missing validation on server
update collections set type='album' where type='CollectionType.album';
CREATE UNIQUE INDEX IF NOT EXISTS collections_uncategorized_constraint_index ON collections (owner_id) WHERE (type = 'uncategorized');
