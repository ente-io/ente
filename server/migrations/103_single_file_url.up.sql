

CREATE TABLE IF NOT EXISTS public_file_tokens
(
    id           text primary key,
    file_id bigint NOT NULL,
    owner_id bigint NOT NULL,
    app text NOT NULL,
    access_token  text   not null,
    valid_till    bigint not null DEFAULT 0,
    device_limit  int    not null DEFAULT 0,
    is_disabled   bool   not null DEFAULT FALSE,
    enable_download bool  not null DEFAULT TRUE,
    pw_hash         TEXT,
    pw_nonce        TEXT,
    mem_limit       BIGINT,
    ops_limit       BIGINT,
    created_at    bigint NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at    bigint NOT NULL DEFAULT now_utc_micro_seconds()
);


CREATE OR REPLACE TRIGGER  update_public_file_tokens_updated_at
    BEFORE UPDATE
    ON public_file_tokens
    FOR EACH ROW
EXECUTE PROCEDURE
    trigger_updated_at_microseconds_column();


CREATE TABLE IF NOT EXISTS public_file_tokens_access_history
(
    id   text NOT NULL,
    ip         text   not null,
    user_agent text   not null,
    created_at bigint NOT NULL DEFAULT now_utc_micro_seconds(),
    CONSTRAINT unique_access_id_ip_ua UNIQUE (id, ip, user_agent),
    CONSTRAINT fk_public_file_history_token_id
        FOREIGN KEY (id)
            REFERENCES public_file_tokens (id)
            ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS public_file_token_unique_idx ON public_file_tokens (access_token) WHERE is_disabled = FALSE;
CREATE INDEX IF NOT EXISTS public_file_tokens_owner_id_updated_at_idx ON public_file_tokens (owner_id, updated_at);
CREATE UNIQUE INDEX IF NOT EXISTS public_active_file_link_unique_idx ON public_file_tokens (file_id, is_disabled) WHERE is_disabled = FALSE;
