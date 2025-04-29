ALTER TABLE
    otts DROP CONSTRAINT otts_ott_key;

ALTER TABLE
    otts
ADD
    CONSTRAINT unique_otts_emailhash_ott UNIQUE (ott, email_hash);
    