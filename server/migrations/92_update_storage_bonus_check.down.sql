ALTER TABLE storage_bonus
    DROP CONSTRAINT IF EXISTS storage_bonus_type_check;

ALTER TABLE storage_bonus
    ADD CONSTRAINT storage_bonus_type_check
        CHECK (type IN ('REFERRAL', 'SIGN_UP', 'ANNIVERSARY', 'ADD_ON_BF_2023', 'ADD_ON_SUPPORT'));
