package repo

import (
	"database/sql"

	"github.com/ente-io/stacktrace"

	"github.com/ente-io/museum/pkg/utils/time"
)

type NotificationHistoryRepository struct {
	DB *sql.DB
}

func (repo *NotificationHistoryRepository) GetLastNotificationTime(userID int64, templateID string) (int64, error) {
	var lastNotificationTime sql.NullInt64
	row := repo.DB.QueryRow(`SELECT MAX(sent_time) FROM notification_history WHERE user_id = $1 and template_id = $2`, userID, templateID)
	err := row.Scan(&lastNotificationTime)
	if err != nil {
		return 0, stacktrace.Propagate(err, "")
	}
	if lastNotificationTime.Valid {
		return lastNotificationTime.Int64, nil
	}
	return 0, nil
}

func (repo *NotificationHistoryRepository) DeleteLastNotification(userID int64, templateID string) error {
	var lastNotificationTime sql.NullInt64
	row := repo.DB.QueryRow(`SELECT MAX(sent_time) FROM notification_history WHERE user_id = $1 and template_id = $2`, userID, templateID)
	err := row.Scan(&lastNotificationTime)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if lastNotificationTime.Valid {
		_, err := repo.DB.Exec(`
			DELETE FROM notification_history 
			WHERE user_id = $1 AND template_id = $2 AND sent_time = $3
		`, userID, templateID, lastNotificationTime.Int64)

		if err != nil {
			return stacktrace.Propagate(err, "failed to delete last notification")
		}
	}
	return nil
}

func (repo *NotificationHistoryRepository) SetLastNotificationTimeToNow(userID int64, templateID string) error {
	_, err := repo.DB.Exec(`INSERT INTO notification_history(user_id, template_id, sent_time) VALUES($1, $2, $3)`,
		userID, templateID, time.Microseconds())
	return stacktrace.Propagate(err, "")
}
