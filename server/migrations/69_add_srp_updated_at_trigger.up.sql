CREATE TRIGGER update_srp_auth_updated_at
    BEFORE UPDATE
    ON srp_auth
    FOR EACH ROW
EXECUTE PROCEDURE
    trigger_updated_at_microseconds_column();

CREATE TRIGGER update_srp_sessions_updated_at
    BEFORE UPDATE
    ON srp_sessions
    FOR EACH ROW
EXECUTE PROCEDURE
    trigger_updated_at_microseconds_column();
