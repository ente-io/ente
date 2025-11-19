package repo

import (
	"context"
	"database/sql"
	"errors"

	"github.com/ente-io/stacktrace"
	"github.com/lib/pq"
)

// UsageRepository defines the methods tracking and fetching usage related date
type UsageRepository struct {
	DB       *sql.DB
	UserRepo *UserRepository
}

// GetUsage  gets the Storage usage of a user
func (repo *UsageRepository) GetUsage(userID int64) (int64, error) {
	row := repo.DB.QueryRow(`SELECT storage_consumed FROM usage WHERE user_id = $1`,
		userID)
	var usage int64
	err := row.Scan(&usage)
	if errors.Is(err, sql.ErrNoRows) {
		return 0, nil
	}
	return usage, stacktrace.Propagate(err, "")
}

// Create inserts a new entry for the given user. If entry already exists, it doesn't nothing
func (repo *UsageRepository) Create(userID int64) error {
	_, err := repo.DB.Exec(`INSERT INTO usage(user_id, storage_consumed) VALUES ($1,$2) ON CONFLICT DO NOTHING;`,
		userID, //$1 user_id
		0,      // $2 initial value for storage consumed
	)
	return stacktrace.Propagate(err, "failed to insert/update")
}

// GetCombinedUsage  gets the sum of Storage usage of the list of userIDS
func (repo *UsageRepository) GetCombinedUsage(ctx context.Context, userIDs []int64) (int64, error) {
	row := repo.DB.QueryRowContext(ctx, `SELECT coalesce(sum(storage_consumed),0) FROM usage WHERE user_id = ANY($1)`,
		pq.Array(userIDs))
	var totalUsage int64
	err := row.Scan(&totalUsage)
	if errors.Is(err, sql.ErrNoRows) {
		return 0, nil
	}
	return totalUsage, stacktrace.Propagate(err, "")
}

// GetLockerUsage gets the Locker storage usage of a user
func (repo *UsageRepository) GetLockerUsage(userID int64) (int64, error) {
	row := repo.DB.QueryRow(`SELECT storage_consumed FROM locker_usage WHERE user_id = $1`, userID)
	var usage int64
	err := row.Scan(&usage)
	if errors.Is(err, sql.ErrNoRows) {
		return 0, nil
	}
	return usage, stacktrace.Propagate(err, "")
}

// GetCombinedLockerUsage gets the sum of Locker storage usage for a list of userIDs
func (repo *UsageRepository) GetCombinedLockerUsage(ctx context.Context, userIDs []int64) (int64, error) {
	row := repo.DB.QueryRowContext(ctx, `SELECT coalesce(sum(storage_consumed),0) FROM locker_usage WHERE user_id = ANY($1)`,
		pq.Array(userIDs))
	var totalUsage int64
	err := row.Scan(&totalUsage)
	if errors.Is(err, sql.ErrNoRows) {
		return 0, nil
	}
	return totalUsage, stacktrace.Propagate(err, "")
}

// StorageForFamilyAdmin calculates the total storage consumed by the family for a given adminID
func (repo *UsageRepository) StorageForFamilyAdmin(adminID int64) (int64, error) {
	query := `
		SELECT COALESCE(SUM(storage_consumed), 0)
		FROM users
		LEFT JOIN families ON users.family_admin_id = families.admin_id AND families.status IN ('SELF', 'ACCEPTED')
		LEFT JOIN usage ON families.member_id = usage.user_id
		WHERE users.user_id = $1
	`
	var totalStorage int64
	err := repo.DB.QueryRow(query, adminID).Scan(&totalStorage)
	if errors.Is(err, sql.ErrNoRows) {
		return 0, nil
	}
	return totalStorage, stacktrace.Propagate(err, "")
}
