ALTER TABLE public_abuse_report
    ADD COLUMN details JSONB,
    DROP COLUMN u_comment;
