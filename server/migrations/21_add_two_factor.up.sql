ALTER TABLE users ADD COLUMN is_two_factor_enabled boolean;
    
UPDATE users SET is_two_factor_enabled = 'f';

ALTER TABLE users ALTER COLUMN is_two_factor_enabled SET NOT NULL;
ALTER TABLE users ALTER COLUMN is_two_factor_enabled SET DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS two_factor(
    user_id INTEGER NOT NULL UNIQUE,
    two_factor_secret_hash TEXT UNIQUE,
    encrypted_two_factor_secret BYTEA,
    two_factor_secret_decryption_nonce BYTEA,
    recovery_encrypted_two_factor_secret TEXT,
    recovery_two_factor_secret_decryption_nonce TEXT,
    CONSTRAINT fk_two_factor_user_id 
		FOREIGN KEY(user_id) 
			REFERENCES users(user_id)
			ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS temp_two_factor(
    user_id INTEGER NOT NULL,
    two_factor_secret_hash TEXT UNIQUE,
    encrypted_two_factor_secret BYTEA,
    two_factor_secret_decryption_nonce BYTEA,
    creation_time BIGINT NOT NULL,
    expiration_time BIGINT NOT NULL,
    CONSTRAINT fk_two_factor_user_id 
		FOREIGN KEY(user_id) 
			REFERENCES users(user_id)
			ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS two_factor_sessions(
    user_id INTEGER NOT NULL,
    session_id TEXT UNIQUE NOT NULL,
    creation_time BIGINT NOT NULL,
    expiration_time BIGINT NOT NULL,
    CONSTRAINT fk_sessions_user_id 
		FOREIGN KEY(user_id) 
			REFERENCES users(user_id)
			ON DELETE CASCADE
);
