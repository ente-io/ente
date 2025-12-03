-- Track used OTP codes to prevent replay attacks
CREATE TABLE IF NOT EXISTS two_factor_used_codes(
    user_id BIGINT NOT NULL,
    code_hash TEXT NOT NULL,
    used_at BIGINT NOT NULL,
    PRIMARY KEY (user_id, code_hash),
    CONSTRAINT fk_two_factor_used_codes_user_id
        FOREIGN KEY(user_id)
            REFERENCES users(user_id)
            ON DELETE CASCADE
);

CREATE INDEX idx_two_factor_used_codes_used_at ON two_factor_used_codes(used_at);
CREATE INDEX idx_two_factor_used_codes_user_id ON two_factor_used_codes(user_id);