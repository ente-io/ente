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
	return repo.SetLastNotificationTimeToNowWithGroup(userID, templateID, "")
}

func (repo *NotificationHistoryRepository) SetLastNotificationTimeToNowWithGroup(userID int64, templateID string, notificationGroup string) error {
	var groupValue sql.NullString
	if notificationGroup != "" {
		groupValue = sql.NullString{
			String: notificationGroup,
			Valid:  true,
		}
	}
	_, err := repo.DB.Exec(`INSERT INTO notification_history(user_id, template_id, sent_time, notification_group) VALUES($1, $2, $3, $4)`,
		userID, templateID, time.Microseconds(), groupValue)
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

func (repo *NotificationHistoryRepository) DeleteNotificationHistoryByGroupExcludingUsers(notificationGroup string, keepUserIDs []int64) error {
	if notificationGroup == "" {
		return nil
	}

	if len(keepUserIDs) == 0 {
		_, err := repo.DB.Exec(`DELETE FROM notification_history WHERE notification_group = $1`, notificationGroup)
		return stacktrace.Propagate(err, "failed to delete grouped notification history")
	}

	_, err := repo.DB.Exec(
		`DELETE FROM notification_history
		 WHERE notification_group = $1
		   AND NOT (user_id = ANY($2))`,
		notificationGroup, pq.Array(keepUserIDs))
	return stacktrace.Propagate(err, "failed to delete grouped notification history")
}
