BEGIN;
ALTER TABLE
    otts DROP CONSTRAINT IF EXISTS unique_otts_emailhash_ott;

ALTER TABLE
    otts
    ADD
        CONSTRAINT  unique_otts_emailhash_app_ott UNIQUE (ott,app, email_hash);
COMMIT;