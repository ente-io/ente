ALTER TABLE
    otts DROP CONSTRAINT unique_otts_emailhash_ott;

ALTER TABLE
    otts
ADD
    CONSTRAINT otts_ott_key UNIQUE (ott);
    