ALTER TABLE kex_store ADD COLUMN user_id BIGINT NOT NULL;

ALTER TABLE kex_store
ADD
    CONSTRAINT fk_kex_store_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;