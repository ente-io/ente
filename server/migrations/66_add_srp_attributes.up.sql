-- This temporary table is used to store the SRP salt and verifier during
-- the SRP registration process or when the user changes their password.
-- Once the user has verified their email address, the salt and verifier
-- are copied to the srp_auth table.
CREATE TABLE IF NOT EXISTS srp_auth (
    user_id BIGINT PRIMARY KEY  NOT NULL,
    srp_user_id uuid NOT NULL UNIQUE,
    salt TEXT NOT NULL,
    verifier TEXT NOT NULL,
    created_at BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
    CONSTRAINT fk_srp_auth_user_id
        FOREIGN KEY (user_id)
            REFERENCES users (user_id)
            ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS temp_srp_setup (
    id uuid PRIMARY KEY  NOT NULL,
    session_id uuid NOT NULL,
    srp_user_id uuid NOT NULL,
    user_id BIGINT NOT NULL,
    salt TEXT NOT NULL,
    verifier TEXT NOT NULL,
    created_at BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
    CONSTRAINT fk_temp_srp_setup_user_id
        FOREIGN KEY (user_id)
            REFERENCES users (user_id)
            ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS srp_sessions (
    id uuid PRIMARY KEY NOT NULL,
    srp_user_id uuid NOT NULL,
    server_key TEXT NOT NULL,
    srp_a TEXT NOT NULL,
    has_verified BOOLEAN NOT NULL DEFAULT false,
    attempt_count INT NOT NULL DEFAULT 0,
    created_at bigint NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at BIGINT NOT NULL DEFAULT now_utc_micro_seconds()
);
