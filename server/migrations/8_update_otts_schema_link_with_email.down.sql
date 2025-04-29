ALTER TABLE otts
    ADD COLUMN user_id INTEGER;

UPDATE  otts
    SET user_id = (SELECT user_id 
                 FROM users 
                 WHERE users.email=otts.email);

ALTER TABLE otts
    DROP COLUMN email,
    ALTER COLUMN user_id SET NOT NULL;
