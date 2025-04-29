-- Replace existing trigger to honor new value of update_at if it's greater than old updated_at
-- The equals check handles the case where the application is only modifying certain property of a row (not updateAt) like file restored or deleted flag. In such cases, the old row's and new row's timestamp will be same, so we are incrementing it.

-- The greater than case handles the case where if application is setting updateAt timestamp lower than currentTimestamp. Ideally, the version should always increase otherwise the diff on client will fail.

create or replace function trigger_updated_at_microseconds_column() returns trigger
    language plpgsql
as
$$
BEGIN
    IF OLD.updated_at >= NEW.updated_at THEN
        NEW.updated_at = now_utc_micro_seconds();
    END IF;
    RETURN NEW;
END;
$$;
