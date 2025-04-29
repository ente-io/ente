ALTER TABLE subscriptions 
    DROP COLUMN attributes,
    DROP CONSTRAINT subscription_user_id_unique_constraint_index,
    ALTER COLUMN latest_verification_data SET NOT NULL;

