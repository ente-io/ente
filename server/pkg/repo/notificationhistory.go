package repo

import (
	"database/sql"
	"github.com/ente-io/stacktrace"
	"github.com/lib/pq"

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

func (repo *NotificationHistoryRepository) SetLastNotificationTimeToNow(userID int64, templateID string) error {
	_, err := repo.DB.Exec(`INSERT INTO notification_history(user_id, template_id, sent_time) VALUES($1, $2, $3)`,
		userID, templateID, time.Microseconds())
	return stacktrace.Propagate(err, "")
}

// GetLastNotificationTimes returns the latest sent_time per templateID for the
// provided user.
func (repo *NotificationHistoryRepository) GetLastNotificationTimes(userID int64, templateIDs []string) (map[string]int64, error) {
	result := make(map[string]int64)
	if len(templateIDs) == 0 {
		return result, nil
	}

	rows, err := repo.DB.Query(
		`SELECT template_id, MAX(sent_time) FROM notification_history
		 WHERE user_id = $1 AND template_id = ANY($2)
		 GROUP BY template_id`,
		userID, pq.Array(templateIDs))
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to fetch notification history")
	}
	defer rows.Close()

	for rows.Next() {
		var templateID string
		var sentTime int64
		if err := rows.Scan(&templateID, &sentTime); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan notification history")
		}
		result[templateID] = sentTime
	}
	if err := rows.Err(); err != nil {
		return nil, stacktrace.Propagate(err, "failed to iterate notification history")
	}

	return result, nil
}
