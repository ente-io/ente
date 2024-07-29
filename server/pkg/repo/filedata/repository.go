package filedata

import (
	"context"
	"database/sql"
	"github.com/ente-io/stacktrace"
	"github.com/lib/pq"
	"github.com/pkg/errors"
)

// FileData represents the structure of the file_data table.
type FileData struct {
	FileID            int64
	UserID            int64
	DataType          string
	Size              int64
	LatestBucket      string
	ReplicatedBuckets []string
	DeleteFromBuckets []string
	PendingSync       bool
	IsDeleted         bool
	LastSyncTime      int64
	CreatedAt         int64
	UpdatedAt         int64
}

// Repository defines the methods for inserting, updating, and retrieving file data.
type Repository struct {
	DB *sql.DB
}

// Insert inserts a new file_data record
func (r *Repository) Insert(ctx context.Context, data FileData) error {
	query := `
		INSERT INTO file_data 
			(file_id, user_id, data_type, size, latest_bucket, replicated_buckets) 
		VALUES 
			($1, $2, $3, $4, $5, $6)
		ON CONFLICT (file_id, data_type)
		DO UPDATE SET 
			size = $4, 
			latest_bucket = $5,
			replicated_buckets = $6	`
	_, err := r.DB.ExecContext(ctx, query,
		data.FileID, data.UserID, data.DataType, data.Size, data.LatestBucket, pq.Array(data.ReplicatedBuckets))
	if err != nil {
		return stacktrace.Propagate(err, "failed to insert file data")
	}
	return nil
}

// UpdateReplicatedBuckets updates the replicated_buckets for a given file and data type.
func (r *Repository) UpdateReplicatedBuckets(ctx context.Context, fileID int64, dataType string, newBuckets []string, previousUpdatedAt int64) error {
	query := `
		UPDATE file_data 
		SET replicated_buckets = $1, updated_at = now_utc_micro_seconds() 
		WHERE file_id = $2 AND data_type = $3 AND updated_at = $4`
	res, err := r.DB.ExecContext(ctx, query, pq.Array(newBuckets), fileID, dataType, previousUpdatedAt)
	if err != nil {
		return errors.Wrap(err, "failed to update replicated buckets")
	}

	rowsAffected, err := res.RowsAffected()
	if err != nil {
		return errors.Wrap(err, "failed to check rows affected")
	}
	if rowsAffected == 0 {
		return errors.New("no rows were updated, possible concurrent modification")
	}
	return nil
}

// UpdateDeleteFromBuckets updates the delete_from_buckets for a given file and data type.
func (r *Repository) UpdateDeleteFromBuckets(ctx context.Context, fileID int64, dataType string, newBuckets []string, previousUpdatedAt int64) error {
	query := `
		UPDATE file_data 
		SET delete_from_buckets = $1, updated_at = now_utc_micro_seconds() 
		WHERE file_id = $2 AND data_type = $3 AND updated_at = $4`
	res, err := r.DB.ExecContext(ctx, query, pq.Array(newBuckets), fileID, dataType, previousUpdatedAt)
	if err != nil {
		return errors.Wrap(err, "failed to update delete from buckets")
	}

	rowsAffected, err := res.RowsAffected()
	if err != nil {
		return errors.Wrap(err, "failed to check rows affected")
	}
	if rowsAffected == 0 {
		return errors.New("no rows were updated, possible concurrent modification")
	}
	return nil
}

// DeleteFileData deletes a file_data record by file_id and data_type if both replicated_buckets and delete_from_buckets are empty.
func (r *Repository) DeleteFileData(ctx context.Context, fileID int64, dataType string, previousUpdatedAt int64) error {
	// First, check if both replicated_buckets and delete_from_buckets are empty.
	var replicatedBuckets, deleteFromBuckets []string
	query := `SELECT replicated_buckets, delete_from_buckets FROM file_data WHERE file_id = $1 AND data_type = $2`
	err := r.DB.QueryRowContext(ctx, query, fileID, dataType).Scan(pq.Array(&replicatedBuckets), pq.Array(&deleteFromBuckets))
	if err != nil {
		if err == sql.ErrNoRows {
			return errors.New("no file data found for the given file_id and data_type")
		}
		return errors.Wrap(err, "failed to check buckets before deleting file data")
	}

	if len(replicatedBuckets) > 0 || len(deleteFromBuckets) > 0 {
		return errors.New("cannot delete file data with non-empty replicated_buckets or delete_from_buckets")
	}

	// Proceed with deletion if both arrays are empty and updated_at matches.
	deleteQuery := `DELETE FROM file_data WHERE file_id = $1 AND data_type = $2 AND updated_at = $3`
	res, err := r.DB.ExecContext(ctx, deleteQuery, fileID, dataType, previousUpdatedAt)
	if err != nil {
		return errors.Wrap(err, "failed to delete file data")
	}

	rowsAffected, err := res.RowsAffected()
	if err != nil {
		return errors.Wrap(err, "failed to check rows affected")
	}
	if rowsAffected == 0 {
		return errors.New("no rows were deleted, possible concurrent modification")
	}
	return nil
}

// GetFileData retrieves a single file_data record by file_id and data_type.
func (r *Repository) GetFileData(ctx context.Context, fileID int64, dataType string) (FileData, error) {
	var data FileData
	query := `SELECT file_id, user_id, data_type, size, latest_bucket, replicated_buckets, delete_from_buckets, pending_sync, is_deleted, last_sync_time, created_at, updated_at 
			  FROM file_data 
			  WHERE file_id = $1 AND data_type = $2`
	err := r.DB.QueryRowContext(ctx, query, fileID, dataType).Scan(
		&data.FileID, &data.UserID, &data.DataType, &data.Size, &data.LatestBucket, pq.Array(&data.ReplicatedBuckets), pq.Array(&data.DeleteFromBuckets), &data.PendingSync, &data.IsDeleted, &data.LastSyncTime, &data.CreatedAt, &data.UpdatedAt,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return FileData{}, errors.Wrap(err, "no file data found")
		}
		return FileData{}, errors.Wrap(err, "failed to retrieve file data")
	}
	return data, nil
}

// ListFileData retrieves all file_data records for a given user_id.
func (r *Repository) ListFileData(ctx context.Context, userID int64) ([]FileData, error) {
	query := `SELECT file_id, user_id, data_type, size, latest_bucket, replicated_buckets, delete_from_buckets, pending_sync, is_deleted, last_sync_time, created_at, updated_at 
			  FROM file_data 
			  WHERE user_id = $1`
	rows, err := r.DB.QueryContext(ctx, query, userID)
	if err != nil {
		return nil, errors.Wrap(err, "failed to list file data")
	}
	defer rows.Close()

	var fileDataList []FileData
	for rows.Next() {
		var data FileData
		err := rows.Scan(
			&data.FileID, &data.UserID, &data.DataType, &data.Size, &data.LatestBucket, pq.Array(&data.ReplicatedBuckets), pq.Array(&data.DeleteFromBuckets), &data.PendingSync, &data.IsDeleted, &data.LastSyncTime, &data.CreatedAt, &data.UpdatedAt,
		)
		if err != nil {
			return nil, errors.Wrap(err, "failed to scan file data row")
		}
		fileDataList = append(fileDataList, data)
	}
	if err = rows.Err(); err != nil {
		return nil, errors.Wrap(err, "error iterating file data rows")
	}
	return fileDataList, nil
}
