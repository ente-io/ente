BEGIN;
ALTER TABLE
    otts DROP CONSTRAINT IF EXISTS unique_otts_emailhash_app_ott;

ALTER TABLE
    otts
    ADD
        CONSTRAINT unique_otts_emailhash_ott UNIQUE (ott, email_hash);
COMMIT;