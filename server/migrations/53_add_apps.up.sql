CREATE TYPE app AS ENUM ('photos','auth');

ALTER TABLE tokens ADD COLUMN app app NOT NULL DEFAULT 'photos';

ALTER TABLE otts ADD COLUMN app app NOT NULL DEFAULT 'photos';
