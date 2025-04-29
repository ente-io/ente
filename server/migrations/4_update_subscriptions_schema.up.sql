ALTER TABLE subscriptions
    ADD COLUMN product_id TEXT NOT NULL,
    ADD COLUMN payment_provider TEXT NOT NULL,
    ADD COLUMN latest_verification_data TEXT NOT NULL;

CREATE INDEX IF NOT EXISTS subscriptions_expiry_time_index ON subscriptions (expiry_time);
