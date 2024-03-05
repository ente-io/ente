CREATE TABLE IF NOT EXISTS two_factor_recovery (
    user_id bigint NOT NULL,
    -- if false, the support team team will not be able to reset the MFA for the user
    enable_admin_mfa_reset boolean NOT NULL DEFAULT true,
    pass_key_reset_key uuid,
    pass_key_reset_enc_data jsonb,
    twofa_key_reset_key uuid,
    twofa_key_reset_enc_data jsonb,
    created_at    bigint NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at    bigint NOT NULL DEFAULT now_utc_micro_seconds()
);

CREATE TRIGGER update_two_factor_recovery_updated_at
    BEFORE UPDATE
    ON two_factor_recovery
    FOR EACH ROW
    EXECUTE PROCEDURE
        trigger_updated_at_microseconds_column();
