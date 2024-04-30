--- Delete all rows from casting table and add a non-nullable column called ip
BEGIN;
DELETE FROM casting;
ALTER TABLE casting ADD COLUMN ip text NOT NULL;
COMMIT;
