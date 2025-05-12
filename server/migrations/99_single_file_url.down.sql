

ALTER TABLE public_abuse_report
    DROP CONSTRAINT IF EXISTS check_share_id_xor_file_share_id,
    DROP CONSTRAINT IF EXISTS fk_public_abuse_report_file_token_id;


DROP INDEX IF EXISTS unique_report_public_collection_id_ip_ua;
DROP INDEX IF EXISTS unique_report_public_file_id_ip_ua;

ALTER TABLE public_abuse_report DROP CONSTRAINT IF EXISTS fk_public_abuse_report_file_token_id;
ALTER TABLE public_abuse_report DROP CONSTRAINT IF EXISTS unique_report_public_file_id_ip_ua;

ALTER TABLE public_abuse_report DROP COLUMN IF EXISTS file_share_id;

ALTER TABLE public_abuse_report
    ADD CONSTRAINT unique_report_sid_ip_ua
        UNIQUE (share_id, ip, user_agent);

CREATE INDEX IF NOT EXISTS public_abuse_share_id_idx
    ON public_abuse_report (share_id);

DROP TABLE IF EXISTS public_file_tokens_access_history;
DROP TABLE IF EXISTS public_file_tokens;
