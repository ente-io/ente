DROP TRIGGER IF EXISTS update_discount_coupons_updated_at ON discount_coupons;
DROP INDEX IF EXISTS discount_coupons_provider_user_unique;
DROP TABLE IF EXISTS discount_coupons;