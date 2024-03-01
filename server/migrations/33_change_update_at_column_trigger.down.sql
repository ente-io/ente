create or replace function trigger_updated_at_microseconds_column() returns trigger
    language plpgsql
as
$$
BEGIN
    NEW.updated_at = now_utc_micro_seconds();
    RETURN NEW;
END;
$$;
