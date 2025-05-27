DO $$
    BEGIN
        IF EXISTS (
                SELECT 1 FROM file_data
                WHERE obj_size IS NOT NULL
                  AND (obj_size > 2147483647 OR obj_size < -2147483648)
            ) THEN
            RAISE EXCEPTION 'Cannot downgrade - some values exceed integer limits';
        END IF;
    END $$;

ALTER TABLE file_data
    ALTER COLUMN obj_size TYPE integer USING obj_size::integer;