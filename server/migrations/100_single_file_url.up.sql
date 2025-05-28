

CREATE TABLE IF NOT EXISTS public_file_tokens
(
    id           text primary key,
    file_id bigint NOT NULL,
    owner_id bigint NOT NULL,
    access_token  text   not null,
    valid_till    bigint not null DEFAULT 0,
    device_limit  int    not null DEFAULT 0,
    is_disabled   bool   not null DEFAULT FALSE,
    enable_download bool  not null DEFAULT TRUE,
    password_info  JSONB,
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

CREATE UNIQUE INDEX IF NOT EXISTS public_access_token_unique_idx ON public_file_tokens (access_token) WHERE is_disabled = FALSE;
CREATE INDEX IF NOT EXISTS public_file_tokens_owner_id_updated_at_idx ON public_file_tokens (owner_id, updated_at);



ALTER TABLE public_abuse_report DROP CONSTRAINT IF EXISTS unique_report_sid_ip_ua;
DROP INDEX IF EXISTS public_abuse_share_id_idx;

ALTER TABLE public_abuse_report ADD COLUMN IF NOT EXISTS file_share_id text;
ALTER TABLE public_abuse_report 
    ADD CONSTRAINT  fk_public_abuse_report_file_token_id
    FOREIGN KEY (file_share_id) 
    REFERENCES public_file_tokens (id) 
    ON DELETE CASCADE;

ALTER TABLE public_abuse_report 
    ADD CONSTRAINT check_share_id_xor_file_share_id 
    CHECK (
        (share_id IS NULL AND file_share_id IS NOT NULL) OR
        (share_id IS NOT NULL AND file_share_id IS NULL)
    );
    

CREATE UNIQUE INDEX unique_report_public_collection_id_ip_ua 
    ON public_abuse_report (share_id, ip, user_agent) 
    WHERE share_id IS NOT NULL;

CREATE UNIQUE INDEX unique_report_public_file_id_ip_ua 
    ON public_abuse_report (file_share_id, ip, user_agent) 
    WHERE file_share_id IS NOT NULL;