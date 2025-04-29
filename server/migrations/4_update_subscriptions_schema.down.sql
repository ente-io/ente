ALTER TABLE subscriptions
    DROP COLUMN product_id,
    DROP COLUMN payment_provider,
    DROP COLUMN latest_verification_data;

DROP INDEX subscriptions_expiry_time_index;
