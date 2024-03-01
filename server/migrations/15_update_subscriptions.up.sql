ALTER TABLE subscriptions
    ADD CONSTRAINT subscription_user_id_unique_constraint_index UNIQUE (user_id),
    ADD COLUMN attributes JSONB;

UPDATE subscriptions 
        SET attributes = 
            CAST('{"latest_verification_data":"' || latest_verification_data ||'"}'
            AS json);

ALTER TABLE subscriptions
    ALTER COLUMN attributes SET NOT NULL,
    ALTER COLUMN latest_verification_data DROP NOT NULL;
    
