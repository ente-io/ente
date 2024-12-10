package emergency

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/lib/pq"
)

type RecoverRow struct {
	ID                 uuid.UUID
	UserID             int64
	EmergencyContactID int64
	Status             ente.RecoveryStatus
	WaitTill           int64
	NextReminderAt     int64
	CreatedAt          int64
}

func (r RecoverRow) CanRecover() error {
	if r.Status != ente.RecoveryStatusReady && r.Status != ente.RecoveryStatusWaiting {
		return fmt.Errorf("recovery status is not waiting or ready")
	}
	if r.WaitTill > time.Microseconds() && r.Status == ente.RecoveryStatusWaiting {
		return fmt.Errorf("recovery wait time is not over")
	}
	return nil
}

func (repo *Repository) InsertIntoRecovery(ctx *gin.Context, req ente.ContactIdentifier, row ContactRow) (bool, error) {
	waitTime := time.MicrosecondsAfterHours(row.NoticePeriodInHrs)
	nextReminder := time.MicrosecondsAfterHours(row.NoticePeriodInHrs - 24)
	if row.NoticePeriodInHrs < 25 {
		nextReminder = time.Microseconds()
	}
	result, err := repo.DB.ExecContext(ctx, `INSERT INTO emergency_recovery (id,user_id, emergency_contact_id, status, wait_till, next_reminder_at) VALUES ($1, $2, $3, $4, $5, $6) on conflict DO NOTHING`,
		uuid.New(), req.UserID, req.EmergencyContactID, ente.RecoveryStatusWaiting, waitTime, nextReminder)
	if err != nil {
		return false, stacktrace.Propagate(err, "")
	}
	count, _ := result.RowsAffected()
	return count > 0, nil
}

func (repo *Repository) GetActiveRecoverySessions(ctx *gin.Context, userID int64) ([]*RecoverRow, error) {
	rows, err := repo.DB.QueryContext(ctx, `SELECT id, user_id, emergency_contact_id, status, wait_till, next_reminder_at, created_at 
FROM emergency_recovery WHERE (user_id=$1  OR emergency_contact_id=$1) AND status= ANY($2)`, userID, pq.Array([]ente.RecoveryStatus{ente.RecoveryStatusWaiting, ente.RecoveryStatusReady}))
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer rows.Close()
	var sessions []*RecoverRow
	for rows.Next() {
		var row RecoverRow
		if err := rows.Scan(&row.ID, &row.UserID, &row.EmergencyContactID, &row.Status, &row.WaitTill, &row.NextReminderAt, &row.CreatedAt); err != nil {
			return nil, stacktrace.Propagate(err, "")
		}
		sessions = append(sessions, &row)
	}
	return sessions, nil
}

func (repo *Repository) UpdateRecoveryStatusForID(ctx context.Context, sessionID uuid.UUID, status ente.RecoveryStatus) (bool, error) {
	validPrevStatus := validPreviousStatus(status)
	var result sql.Result
	var err error
	if status == ente.RecoveryStatusReady {
		result, err = repo.DB.ExecContext(ctx, `UPDATE emergency_recovery SET status=$1, wait_till=$2 WHERE id=$3 and status = ANY($4)`, status, time.Microseconds(), sessionID, pq.Array(validPrevStatus))
	} else {
		result, err = repo.DB.ExecContext(ctx, `UPDATE emergency_recovery SET status=$1 WHERE id=$2 and status = ANY($3)`, status, sessionID, pq.Array(validPrevStatus))
	}
	if err != nil {
		return false, stacktrace.Propagate(err, "")
	}
	rows, _ := result.RowsAffected()
	return rows > 0, nil
}
func (repo *Repository) GetRecoverRowByID(ctx context.Context, sessionID uuid.UUID) (*RecoverRow, error) {
	var row RecoverRow
	err := repo.DB.QueryRowContext(ctx, `SELECT id, user_id, emergency_contact_id, status, wait_till, next_reminder_at, created_at
	FROM emergency_recovery WHERE id=$1`, sessionID).Scan(&row.ID, &row.UserID, &row.EmergencyContactID, &row.Status, &row.WaitTill, &row.NextReminderAt, &row.CreatedAt)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &row, nil
}

func (repo *Repository) UpdateRecoveryStatus(ctx context.Context, userID, emergencyContactID int64, status ente.RecoveryStatus) error {
	validPrevStatus := validPreviousStatus(status)
	_, err := repo.DB.ExecContext(ctx, `UPDATE emergency_recovery SET status=$1 WHERE user_id =$2 and emergency_contact_id =$3 and status = ANY($4)`, status, userID, emergencyContactID, pq.Array(validPrevStatus))
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

func validPreviousStatus(newStatus ente.RecoveryStatus) []ente.RecoveryStatus {
	result := make([]ente.RecoveryStatus, 0)
	switch newStatus {
	case ente.RecoveryStatusWaiting:
		break
	case ente.RecoveryStatusReady:
		result = append(result, ente.RecoveryStatusWaiting, ente.RecoveryStatusReady)
	case ente.RecoveryStatusStopped:
		result = append(result, ente.RecoveryStatusWaiting, ente.RecoveryStatusReady)
	case ente.RecoveryStatusRejected:
		result = append(result, ente.RecoveryStatusWaiting, ente.RecoveryStatusReady)
	case ente.RecoveryStatusRecovered:
		result = append(result, ente.RecoveryStatusWaiting, ente.RecoveryStatusReady)
	}
	return result
}
