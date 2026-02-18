CREATE TABLE IF NOT EXISTS public_paste_tokens
(
    id                text PRIMARY KEY,
    access_token      text   NOT NULL UNIQUE,
    encrypted_data    text   NOT NULL,
    decryption_header text   NOT NULL,
    expires_at        bigint NOT NULL,
    created_at        bigint NOT NULL DEFAULT now_utc_micro_seconds()
);

CREATE INDEX IF NOT EXISTS public_paste_tokens_expires_at_idx
    ON public_paste_tokens (expires_at);
