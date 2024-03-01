ALTER TABLE key_attributes ADD COLUMN mem_limit INTEGER DEFAULT 67108864;

UPDATE key_attributes SET mem_limit = 67108864; -- crypto_pwhash_MEMLIMIT_INTERACTIVE

ALTER TABLE key_attributes ADD COLUMN ops_limit INTEGER DEFAULT 2;

UPDATE key_attributes SET ops_limit = 2;  -- crypto_pwhash_OPSLIMIT_INTERACTIVE
