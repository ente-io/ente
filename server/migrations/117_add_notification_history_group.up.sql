ALTER TABLE notification_history
    ADD COLUMN IF NOT EXISTS notification_group TEXT;

UPDATE notification_history
SET notification_group = 'storage_warning_active_overage'
WHERE template_id IN (
    'family_storage_warning_active_overage',
    'family_storage_warning_active_overage_30d',
    'family_storage_warning_active_overage_60d',
    'family_storage_warning_active_overage_89d'
);

UPDATE notification_history
SET notification_group = 'storage_warning_expired'
WHERE template_id IN (
    'family_storage_warning_expired_30d',
    'family_storage_warning_expired_60d',
    'family_storage_warning_expired_90d',
    'family_storage_warning_expired_119d'
);

CREATE INDEX IF NOT EXISTS notification_history_user_template_sent_time_idx
    ON notification_history(user_id, template_id, sent_time DESC);

CREATE INDEX IF NOT EXISTS notification_history_group_user_id_idx
    ON notification_history(notification_group, user_id);
