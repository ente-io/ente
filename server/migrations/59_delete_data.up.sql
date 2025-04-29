CREATE TYPE stage_enum AS ENUM ('scheduled', 'collection', 'trash', 'storage', 'completed');

CREATE TABLE IF NOT EXISTS data_cleanup
(
    user_id             BIGINT PRIMARY KEY,
    stage               stage_enum NOT NULL DEFAULT 'scheduled',
    stage_schedule_time BIGINT     NOT NULL DEFAULT now_utc_micro_seconds() + (7 * 24::BIGINT * 60 * 60 * 1000 * 1000),
    stage_attempt_count int        NOT NULL DEFAULT 0,
    status              TEXT       NOT NULL DEFAULT '',
    created_at          bigint     NOT NULL DEFAULT now_utc_micro_seconds(),
    updated_at          bigint     NOT NULL DEFAULT now_utc_micro_seconds()
);

insert into data_cleanup(user_id, stage_schedule_time) (select u.user_id,
                                                          GREATEST(max(t.last_used_at) +
                                                                (7::BIGINT * 24 * 60 * 60 * 1000 * 1000),
                                                                now_utc_micro_seconds())
                                                   from users u
                                                            left join tokens t
                                                                      on t.user_id = u.user_id
                                                   where u.encrypted_email is NULL
                                                     and u.email_hash like '%deleted%'
                                                   group by u.user_id);
