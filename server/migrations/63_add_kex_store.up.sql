CREATE TABLE IF NOT EXISTS kex_store (
    id TEXT UNIQUE PRIMARY KEY NOT NULL,
    user_id BIGINT NOT NULL,
    wrapped_key TEXT NOT NULL,
    added_at BIGINT NOT NULL,
    CONSTRAINT fk_kex_store_user_id FOREIGN KEY(user_id) REFERENCES users(user_id) ON DELETE CASCADE
);