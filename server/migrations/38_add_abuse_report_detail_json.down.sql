ALTER TABLE public_abuse_report 
    DROP COLUMN details,
    ADD COLUMN u_comment  varchar(10000) not null DEFAULT '';
