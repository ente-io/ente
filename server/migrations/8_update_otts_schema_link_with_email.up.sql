ALTER TABLE otts
    ADD COLUMN email TEXT;

UPDATE otts
    SET email = (SELECT email 
                 FROM users 
                 WHERE users.user_id=otts.user_id);

ALTER TABLE otts
    DROP COLUMN user_id,
    ALTER COLUMN email SET NOT NULL;
