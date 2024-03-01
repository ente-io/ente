CREATE TABLE IF NOT EXISTS notification_history (
    user_id INTEGER NOT NULL,
    template_id TEXT NOT NULL,
    sent_time BIGINT NOT NULL,

	CONSTRAINT fk_notification_history_user_id 
		FOREIGN KEY(user_id) 
			REFERENCES users(user_id)
			ON DELETE CASCADE
);
