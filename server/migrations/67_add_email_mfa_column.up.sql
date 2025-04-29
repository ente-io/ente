--- Add email_mfa bool column to users table with default value same as is_two_factor_enabled
--- Alter the column to not null after back-filling data

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS email_mfa boolean DEFAULT false;
UPDATE users
SET email_mfa = NOT is_two_factor_enabled;
ALTER TABLE users
    ALTER COLUMN email_mfa SET NOT NULL;

