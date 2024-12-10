DROP TRIGGER IF EXISTS update_emergency_recovery_updated_at ON emergency_recovery;
DROP TRIGGER IF EXISTS update_emergency_conctact_updated_at ON emergency_contact;

DROP INDEX IF EXISTS idx_emergency_recovery_next_reminder_at;
DROP INDEX IF EXISTS idx_emergency_recovery_user_id;
DROP INDEX IF EXISTS idx_emergency_contact_id;
DROP INDEX IF EXISTS idx_emergency_recovery_limit_active_recovery;

DROP TABLE IF EXISTS emergency_recovery;
DROP TABLE IF EXISTS emergency_contact;

DROP FUNCTION IF EXISTS trigger_updated_at_microseconds_column;
