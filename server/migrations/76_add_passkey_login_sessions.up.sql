CREATE TABLE IF NOT EXISTS passkey_login_sessions(
    user_id BIGINT NOT NULL,
    session_id TEXT UNIQUE NOT NULL,
    creation_time BIGINT NOT NULL,
    expiration_time BIGINT NOT NULL,
    CONSTRAINT fk_passkey_login_sessions_user_id
        FOREIGN KEY(user_id)
            REFERENCES users(user_id)
            ON DELETE CASCADE
);