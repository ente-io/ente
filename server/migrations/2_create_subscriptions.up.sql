CREATE TABLE IF NOT EXISTS subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    storage_in_mbs BIGINT NOT NULL,
    original_transaction_id TEXT NOT NULL,
    expiry_time BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

	CONSTRAINT fk_subscriptions_user_id 
		FOREIGN KEY(user_id) 
			REFERENCES users(user_id)
			ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS subscription_logs (
    log_id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    payment_provider TEXT NOT NULL,
    notification JSONB NOT NULL,
    verification_response JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_subscription_logs_user_id 
		FOREIGN KEY(user_id) 
			REFERENCES users(user_id)
			ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS subscriptions_user_id_index ON subscriptions(user_id);
