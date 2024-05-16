-- Add types for the new dcs that are introduced for the derived data
ALTER TABLE embeddings DROP COLUMN IF EXISTS datacenters;
