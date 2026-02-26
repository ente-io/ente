CREATE TABLE discount_coupons (
    provider_name TEXT NOT NULL,
    code TEXT NOT NULL,
    claimed_by_user_id BIGINT DEFAULT NULL,
    claimed_at BIGINT DEFAULT NULL,
    sent_count INTEGER DEFAULT 0,
    created_at BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at BIGINT NOT NULL DEFAULT now_utc_micro_seconds(),
    CONSTRAINT discount_coupons_provider_code_unique UNIQUE (provider_name, code)
);

CREATE UNIQUE INDEX discount_coupons_provider_user_unique 
ON discount_coupons (provider_name, claimed_by_user_id) 
WHERE claimed_by_user_id IS NOT NULL;

CREATE TRIGGER update_discount_coupons_updated_at
    BEFORE UPDATE
    ON discount_coupons
    FOR EACH ROW
EXECUTE PROCEDURE
    trigger_updated_at_microseconds_column();