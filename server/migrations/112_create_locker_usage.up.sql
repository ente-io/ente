CREATE TABLE IF NOT EXISTS locker_usage(
    user_id BIGINT NOT NULL,
    storage_consumed BIGINT NOT NULL,

    CONSTRAINT pk_locker_usage PRIMARY KEY(user_id),
    CONSTRAINT fk_locker_usage_user_id
        FOREIGN KEY(user_id)
            REFERENCES users(user_id)
            ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS locker_usage_user_id_index ON locker_usage(user_id);
