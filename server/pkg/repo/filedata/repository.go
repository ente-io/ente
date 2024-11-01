package filedata

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/ente/filedata"
	"github.com/ente-io/museum/pkg/utils/array"
	"github.com/ente-io/stacktrace"
	"github.com/lib/pq"
	"time"
)

// Repository defines the methods for inserting, updating, and retrieving file data.
type Repository struct {
	DB *sql.DB
}

const (
	ReplicationColumn = "replicated_buckets"
	DeletionColumn    = "delete_from_buckets"
	InflightRepColumn = "inflight_rep_buckets"
)

func (r *Repository) InsertOrUpdate(ctx context.Context, data filedata.Row) error {
	query := `
        INSERT INTO file_data 
            (file_id, user_id, data_type, size, latest_bucket) 
        VALUES 
            ($1, $2, $3, $4, $5)
        ON CONFLICT (file_id, data_type)
        DO UPDATE SET 
            size = EXCLUDED.size,
            delete_from_buckets = array(
                SELECT DISTINCT elem FROM unnest(
                    array_append(
                        array_cat(array_cat(file_data.replicated_buckets, file_data.delete_from_buckets), file_data.inflight_rep_buckets),
                        CASE WHEN file_data.latest_bucket != EXCLUDED.latest_bucket THEN file_data.latest_bucket  END
                    )
                ) AS elem
                WHERE elem IS NOT NULL AND elem != EXCLUDED.latest_bucket
            ),
            replicated_buckets = ARRAY[]::s3region[],
            pending_sync = true,
            latest_bucket = EXCLUDED.latest_bucket,
            updated_at = now_utc_micro_seconds()
        WHERE file_data.is_deleted = false`
	_, err := r.DB.ExecContext(ctx, query,
		data.FileID, data.UserID, string(data.Type), data.Size, data.LatestBucket)
	if err != nil {
		return stacktrace.Propagate(err, "failed to insert file data")
	}
	return nil
}

func (r *Repository) GetFilesData(ctx context.Context, oType ente.ObjectType, fileIDs []int64) ([]filedata.Row, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT file_id, user_id, data_type, size, latest_bucket, replicated_buckets, delete_from_buckets, inflight_rep_buckets, pending_sync, is_deleted, sync_locked_till, created_at, updated_at
										FROM file_data
										WHERE data_type = $1 AND file_id = ANY($2)`, string(oType), pq.Array(fileIDs))
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return convertRowsToFilesData(rows)
}

func (r *Repository) GetFileData(ctx context.Context, fileIDs int64) ([]filedata.Row, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT file_id, user_id, data_type, size, latest_bucket, replicated_buckets, delete_from_buckets,inflight_rep_buckets, pending_sync, is_deleted, sync_locked_till, created_at, updated_at
										FROM file_data
										WHERE file_id = $1`, fileIDs)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return convertRowsToFilesData(rows)
}

func (r *Repository) AddBucket(row filedata.Row, bucketID string, columnName string) error {
	query := fmt.Sprintf(`
        UPDATE file_data
        SET %s = array(
            SELECT DISTINCT elem FROM unnest(
                array_append(file_data.%s, $1)
            ) AS elem
        )
        WHERE file_id = $2 AND data_type = $3 and user_id = $4`, columnName, columnName)
	result, err := r.DB.Exec(query, bucketID, row.FileID, string(row.Type), row.UserID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to add bucket to "+columnName)
	}
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if rowsAffected == 0 {
		return stacktrace.NewError("bucket not added to " + columnName)
	}
	return nil
}

func (r *Repository) RemoveBucket(row filedata.Row, bucketID string, columnName string) error {
	query := fmt.Sprintf(`
        UPDATE file_data
        SET %s = array(
            SELECT DISTINCT elem FROM unnest(
                array_remove(
                    file_data.%s,
                    $1
                )
            ) AS elem
            WHERE elem IS NOT NULL
        )
        WHERE file_id = $2 AND data_type = $3 and user_id = $4`, columnName, columnName)
	result, err := r.DB.Exec(query, bucketID, row.FileID, string(row.Type), row.UserID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to remove bucket from "+columnName)
	}
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if rowsAffected == 0 {
		return stacktrace.NewError("bucket not removed from " + columnName)
	}
	return nil
}

func (r *Repository) GetIndexStatusForUser(ctx context.Context, userID int64, lastUpdatedAt int64, limit int64) ([]filedata.IndexStatus, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT file_id, user_id, data_type, size, is_deleted, updated_at
										FROM file_data
										WHERE user_id = $1 AND updated_at > $2 ORDER BY updated_at  
										LIMIT $3`, userID, lastUpdatedAt, limit)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	var indexStatuses []filedata.IndexStatus
	for rows.Next() {
		var indexStatus filedata.IndexStatus
		scanErr := rows.Scan(&indexStatus.FileID, &indexStatus.UserID, &indexStatus.Type, &indexStatus.Size, &indexStatus.IsDeleted, &indexStatus.UpdatedAt)
		if scanErr != nil {
			return nil, stacktrace.Propagate(scanErr, "")
		}
		indexStatuses = append(indexStatuses, indexStatus)
	}
	return indexStatuses, nil
}

func (r *Repository) MoveBetweenBuckets(row filedata.Row, bucketID string, sourceColumn string, destColumn string) error {
	query := fmt.Sprintf(`
  UPDATE file_data
  SET %s = array(
   SELECT DISTINCT elem FROM unnest(
    array_append(
     file_data.%s,
     $1
    )
   ) AS elem
   WHERE elem IS NOT NULL
  ),
  %s = array(
   SELECT DISTINCT elem FROM unnest(
    array_remove(
     file_data.%s,
     $1
    )
   ) AS elem
   WHERE elem IS NOT NULL
  )
  WHERE file_id = $2 AND data_type = $3 and user_id = $4`, destColumn, destColumn, sourceColumn, sourceColumn)
	result, err := r.DB.Exec(query, bucketID, row.FileID, string(row.Type), row.UserID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to move bucket from "+sourceColumn+" to "+destColumn)
	}
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if rowsAffected == 0 {
		return stacktrace.NewError("bucket not moved from " + sourceColumn + " to " + destColumn)
	}
	return nil
}

// GetPendingSyncDataAndExtendLock in a transaction gets single file data row that has been deleted and pending sync is true and sync_lock_till is less than now_utc_micro_seconds() and extends the lock till newSyncLockTime
// This is used to lock the file data row for deletion and extend
func (r *Repository) GetPendingSyncDataAndExtendLock(ctx context.Context, newSyncLockTime int64, forDeletion bool) (*filedata.Row, error) {
	// ensure newSyncLockTime is in the future
	if newSyncLockTime < time.Now().Add(5*time.Minute).UnixMicro() {
		return nil, stacktrace.NewError("newSyncLockTime should be at least 5min in the future")
	}
	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer tx.Rollback()
	row := tx.QueryRow(`SELECT file_id, user_id, data_type, size, latest_bucket, replicated_buckets, delete_from_buckets, inflight_rep_buckets, pending_sync, is_deleted, sync_locked_till, created_at, updated_at
		FROM file_data
		where pending_sync = true and is_deleted = $1 and sync_locked_till < now_utc_micro_seconds()
		LIMIT 1
		FOR UPDATE SKIP LOCKED`, forDeletion)
	var fileData filedata.Row
	err = row.Scan(&fileData.FileID, &fileData.UserID, &fileData.Type, &fileData.Size, &fileData.LatestBucket, pq.Array(&fileData.ReplicatedBuckets), pq.Array(&fileData.DeleteFromBuckets), pq.Array(&fileData.InflightReplicas), &fileData.PendingSync, &fileData.IsDeleted, &fileData.SyncLockedTill, &fileData.CreatedAt, &fileData.UpdatedAt)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if fileData.SyncLockedTill > newSyncLockTime {
		return nil, stacktrace.NewError(fmt.Sprintf("newSyncLockTime (%d) is less than existing SyncLockedTill(%d), newSync", newSyncLockTime, fileData.SyncLockedTill))
	}
	_, err = tx.Exec(`UPDATE file_data SET sync_locked_till = $1 WHERE file_id = $2 AND data_type = $3 AND user_id = $4`, newSyncLockTime, fileData.FileID, string(fileData.Type), fileData.UserID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	err = tx.Commit()
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &fileData, nil
}

// MarkReplicationAsDone marks the pending_sync as false for the file data row, while
// ensuring that the row is not deleted
func (r *Repository) MarkReplicationAsDone(ctx context.Context, row filedata.Row) error {
	query := `UPDATE file_data SET pending_sync = false WHERE is_deleted=false and file_id = $1 AND data_type = $2 AND user_id = $3`
	_, err := r.DB.ExecContext(ctx, query, row.FileID, string(row.Type), row.UserID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

func (r *Repository) RegisterReplicationAttempt(ctx context.Context, row filedata.Row, dstBucketID string) error {
	if array.StringInList(dstBucketID, row.DeleteFromBuckets) {
		return r.MoveBetweenBuckets(row, dstBucketID, DeletionColumn, InflightRepColumn)
	}
	if !array.StringInList(dstBucketID, row.InflightReplicas) {
		return r.AddBucket(row, dstBucketID, InflightRepColumn)
	}
	return nil
}

// ResetSyncLock resets the sync_locked_till to now_utc_micro_seconds() for the file data row only if pending_sync is false and
// the input syncLockedTill is equal to the existing sync_locked_till. This is used to reset the lock after the replication is done
func (r *Repository) ResetSyncLock(ctx context.Context, row filedata.Row, syncLockedTill int64) error {
	query := `UPDATE file_data SET sync_locked_till = now_utc_micro_seconds() WHERE pending_sync = false and file_id = $1 AND data_type = $2 AND user_id = $3 AND sync_locked_till = $4`
	_, err := r.DB.ExecContext(ctx, query, row.FileID, string(row.Type), row.UserID, syncLockedTill)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

func (r *Repository) DeleteFileData(ctx context.Context, row filedata.Row) error {
	query := `
	DELETE FROM file_data
	WHERE file_id = $1 AND data_type = $2 AND latest_bucket = $3 AND user_id = $4 
  	AND replicated_buckets = ARRAY[]::s3region[] AND delete_from_buckets = ARRAY[]::s3region[] and inflight_rep_buckets = ARRAY[]::s3region[] and is_deleted=True`
	res, err := r.DB.ExecContext(ctx, query, row.FileID, string(row.Type), row.LatestBucket, row.UserID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	rowsAffected, err := res.RowsAffected()
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if rowsAffected == 0 {
		return stacktrace.NewError("file data not deleted")
	}
	return nil
}

func convertRowsToFilesData(rows *sql.Rows) ([]filedata.Row, error) {
	var filesData []filedata.Row
	for rows.Next() {
		var fileData filedata.Row
		err := rows.Scan(&fileData.FileID, &fileData.UserID, &fileData.Type, &fileData.Size, &fileData.LatestBucket, pq.Array(&fileData.ReplicatedBuckets), pq.Array(&fileData.DeleteFromBuckets), pq.Array(&fileData.InflightReplicas), &fileData.PendingSync, &fileData.IsDeleted, &fileData.SyncLockedTill, &fileData.CreatedAt, &fileData.UpdatedAt)
		if err != nil {
			return nil, stacktrace.Propagate(err, "")
		}
		filesData = append(filesData, fileData)
	}
	return filesData, nil
}
