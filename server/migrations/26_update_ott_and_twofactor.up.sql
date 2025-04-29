ALTER TABLE otts
    ADD COLUMN wrong_attempt INTEGER DEFAULT 0;

ALTER TABLE two_factor_sessions
    ADD COLUMN wrong_attempt INTEGER DEFAULT 0;

BEGIN;
UPDATE otts set wrong_attempt = 0 where wrong_attempt is null;

ALTER TABLE otts
    ALTER COLUMN wrong_attempt SET NOT NULL;
COMMIT;

BEGIN;
UPDATE two_factor_sessions set wrong_attempt = 0 where wrong_attempt is null;

ALTER TABLE two_factor_sessions
    ALTER COLUMN wrong_attempt SET NOT NULL;
COMMIT;
