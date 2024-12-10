package datacleanup

import (
	"context"
	"database/sql"
	"fmt"
	entity "github.com/ente-io/museum/ente/data_cleanup"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
)

// Repository wraps out interaction related to data_cleanup database table
type Repository struct {
	DB *sql.DB
}

func (r *Repository) Insert(ctx context.Context, userID int64) error {
	_, err := r.DB.ExecContext(ctx, `INSERT INTO data_cleanup(user_id) VALUES ($1)`, userID)
	return stacktrace.Propagate(err, "failed to insert")
}

func (r *Repository) RemoveScheduledDelete(ctx context.Context, userID int64) error {
	res, execErr := r.DB.ExecContext(ctx, `DELETE from data_cleanup where user_id= $1 and stage = $2`, userID, entity.Scheduled)
	if execErr != nil {
		return execErr
	}
	affected, affErr := res.RowsAffected()
	if affErr != nil {
		return affErr
	}
	if affected != 1 {
		return fmt.Errorf("only one row should have been affected, got %d", affected)
	}
	return nil
}

func (r *Repository) GetItemsPendingCompletion(ctx context.Context, limit int) ([]*entity.DataCleanup, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT user_id, stage, stage_schedule_time, stage_attempt_count, created_at, updated_at  from  data_cleanup 
         where stage != $1 and stage_schedule_time < now_utc_micro_seconds() 
         ORDER BY stage_schedule_time LIMIT $2`, entity.Completed, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make([]*entity.DataCleanup, 0)

	for rows.Next() {
		item := entity.DataCleanup{}
		if err = rows.Scan(&item.UserID, &item.Stage, &item.StageScheduleTime, &item.StageAttemptCount, &item.CreatedAt, &item.UpdatedAt); err != nil {
			return nil, stacktrace.Propagate(err, "")
		}

		result = append(result, &item)
	}
	return result, nil
}

// MoveToNextStage update stage with corresponding schedule
func (r *Repository) MoveToNextStage(ctx context.Context, userID int64, stage entity.Stage, stageScheduleTime int64) error {
	_, err := r.DB.ExecContext(ctx, `UPDATE data_cleanup SET stage = $1,stage_schedule_time = $2, stage_attempt_count=0
			 WHERE user_id = $3`, stage, stageScheduleTime, userID)
	return stacktrace.Propagate(err, "failed to insert/update")
}

// ScheduleNextAttemptAfterNHours bumps the attempt count by one and schedule next attempt after n hr(s)
func (r *Repository) ScheduleNextAttemptAfterNHours(ctx context.Context, userID int64, n int32) error {
	_, err := r.DB.ExecContext(ctx, `UPDATE data_cleanup SET stage_attempt_count = stage_attempt_count +1, stage_schedule_time = $1
			 WHERE user_id = $2`, time.MicrosecondsAfterHours(n), userID)
	return stacktrace.Propagate(err, "failed to insert/update")
}

func (r *Repository) DeleteTableData(ctx context.Context, userID int64) error {
	_, err := r.DB.ExecContext(ctx, `DELETE FROM key_attributes WHERE user_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete key attributes data")
	}
	_, err = r.DB.ExecContext(ctx, `DELETE FROM authenticator_key WHERE user_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete auth data")
	}
	_, err = r.DB.ExecContext(ctx, `DELETE FROM entity_key WHERE user_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete entity key data")
	}
	// delete entity_data
	_, err = r.DB.ExecContext(ctx, `DELETE FROM entity_data WHERE user_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete entity data")
	}
	// deleting casting data
	_, err = r.DB.ExecContext(ctx, `DELETE FROM casting WHERE cast_user = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete casting data")
	}
	// delete notification_history data
	_, err = r.DB.ExecContext(ctx, `DELETE FROM notification_history WHERE user_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete notification history data")
	}
	// delete families data
	_, err = r.DB.ExecContext(ctx, `DELETE FROM families WHERE admin_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete family data")
	}

	// delete passkeys (this also clears passkey_credentials via foreign key constraint)
	_, err = r.DB.ExecContext(ctx, `DELETE FROM passkeys WHERE user_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete passkeys data")
	}
	// delete passkey_login_sessions
	_, err = r.DB.ExecContext(ctx, `DELETE FROM passkey_login_sessions WHERE user_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete passkey login sessions data")
	}
	_, err = r.DB.ExecContext(ctx, `DELETE FROM remote_store WHERE user_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete remote store data")
	}

	// delete srp_auth data
	_, err = r.DB.ExecContext(ctx, `DELETE FROM srp_auth WHERE user_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete srp auth data")
	}
	// delete temp_srp_setup data
	_, err = r.DB.ExecContext(ctx, `DELETE FROM temp_srp_setup WHERE user_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete temp srp setup data")
	}
	// delete two_factor data
	_, err = r.DB.ExecContext(ctx, `DELETE FROM two_factor WHERE user_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete two factor data")
	}
	// delete tokens data
	_, err = r.DB.ExecContext(ctx, `DELETE FROM tokens WHERE user_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete tokens data")
	}
	// delete webauthn_sessions data
	_, err = r.DB.ExecContext(ctx, `DELETE FROM webauthn_sessions WHERE user_id = $1`, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete web auth sessions data")
	}
	return nil
}
