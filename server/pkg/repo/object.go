package repo

import (
	"context"
	"database/sql"
	"errors"
	"math/rand"
	"strconv"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
	"github.com/lib/pq"
)

type ObjectRepository struct {
	DB        *sql.DB
	QueueRepo *QueueRepository
}

func (repo *ObjectRepository) GetObjectsMissingInDC(dc string, limit int, random bool) ([]ente.S3ObjectKey, error) {
	rows, err := repo.DB.Query(`SELECT file_id, o_type, object_key, size FROM object_keys 
		WHERE is_deleted = false AND NOT($1 = ANY(datacenters)) limit $2`, dc, limit)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	files, err := convertRowsToObjectKeys(rows)
	if err != nil {
		return files, stacktrace.Propagate(err, "")
	}

	if random && files != nil && len(files) > 0 {
		rand.Shuffle(len(files), func(i, j int) { files[i], files[j] = files[j], files[i] })
	}

	return files, nil
}

func (repo *ObjectRepository) MarkObjectReplicated(objectKey string, datacenter string) (int64, error) {
	result, err := repo.DB.Exec(`UPDATE object_keys SET datacenters = datacenters || $1::s3region WHERE object_key = $2`,
		datacenter, objectKey)
	if err != nil {
		return 0, stacktrace.Propagate(err, "")
	}
	return result.RowsAffected()
}

func (repo *ObjectRepository) GetObjectsForFileIDs(fileIDs []int64) ([]ente.S3ObjectKey, error) {
	rows, err := repo.DB.Query(`SELECT file_id, o_type, object_key, size FROM object_keys 
		WHERE file_id = ANY($1) AND is_deleted=false`, pq.Array(fileIDs))
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return convertRowsToObjectKeys(rows)
}

// GetObject returns the ente.S3ObjectKey key for a file id and type
func (repo *ObjectRepository) GetObject(fileID int64, objType ente.ObjectType) (ente.S3ObjectKey, error) {
	// todo: handling of deleted objects
	row := repo.DB.QueryRow(`SELECT object_key, size, o_type FROM object_keys WHERE file_id = $1 AND o_type = $2 AND is_deleted=false`,
		fileID, objType)
	var s3ObjectKey ente.S3ObjectKey
	s3ObjectKey.FileID = fileID
	err := row.Scan(&s3ObjectKey.ObjectKey, &s3ObjectKey.FileSize, &s3ObjectKey.Type)
	return s3ObjectKey, stacktrace.Propagate(err, "")
}

func (repo *ObjectRepository) GetObjectWithDCs(fileID int64, objType ente.ObjectType) (ente.S3ObjectKey, []string, error) {
	row := repo.DB.QueryRow(`SELECT object_key, size, o_type, datacenters FROM object_keys WHERE file_id = $1 AND o_type = $2 AND is_deleted=false`,
		fileID, objType)
	var s3ObjectKey ente.S3ObjectKey
	var datacenters []string
	s3ObjectKey.FileID = fileID
	err := row.Scan(&s3ObjectKey.ObjectKey, &s3ObjectKey.FileSize, &s3ObjectKey.Type, pq.Array(&datacenters))
	return s3ObjectKey, datacenters, stacktrace.Propagate(err, "")
}

func (repo *ObjectRepository) GetAllFileObjectsByObjectKey(objectKey string) ([]ente.S3ObjectKey, error) {
	rows, err := repo.DB.Query(`SELECT file_id, o_type, object_key, size from object_keys where file_id in 
                                                                (select file_id from object_keys where object_key= $1) 
                                                            and is_deleted=false`, objectKey)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return convertRowsToObjectKeys(rows)
}

func (repo *ObjectRepository) GetDataCentersForObject(objectKey string) ([]string, error) {
	rows, err := repo.DB.Query(`select jsonb_array_elements_text(to_jsonb(datacenters)) from object_keys where object_key = $1`, objectKey)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer rows.Close()
	datacenters := make([]string, 0)
	for rows.Next() {
		var dc string
		err := rows.Scan(&dc)
		if err != nil {
			return datacenters, stacktrace.Propagate(err, "")
		}
		datacenters = append(datacenters, dc)
	}
	return datacenters, nil
}

func (repo *ObjectRepository) RemoveDataCenterFromObject(objectKey string, datacenter string) error {
	_, err := repo.DB.Exec(`UPDATE object_keys SET datacenters = array_remove(datacenters, $1) WHERE object_key = $2`,
		datacenter, objectKey)
	return stacktrace.Propagate(err, "")
}

// RemoveObjectsForKey removes the keys of a deleted object from our tables
func (repo *ObjectRepository) RemoveObjectsForKey(objectKey string) error {
	_, err := repo.DB.Exec(`DELETE FROM object_keys WHERE object_key = $1 AND is_deleted = TRUE`,
		objectKey)
	return stacktrace.Propagate(err, "")
}

// MarkObjectsAsDeletedForFileIDs marks the object keys corresponding to the given filesIDs as deleted
// The actual deletion happens later when the queue is processed
func (repo *ObjectRepository) MarkObjectsAsDeletedForFileIDs(ctx context.Context, tx *sql.Tx, fileIDs []int64) ([]ente.S3ObjectKey, error) {
	rows, err := tx.QueryContext(ctx, `SELECT file_id, o_type, object_key, size FROM object_keys 
		WHERE file_id = ANY($1) AND is_deleted=false FOR UPDATE`, pq.Array(fileIDs))
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	s3ObjectKeys, err := convertRowsToObjectKeys(rows)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	var keysToBeDeleted []string
	for _, s3ObjectKey := range s3ObjectKeys {
		keysToBeDeleted = append(keysToBeDeleted, s3ObjectKey.ObjectKey)
	}

	err = repo.QueueRepo.AddItems(ctx, tx, RemoveComplianceHoldQueue, keysToBeDeleted)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	err = repo.QueueRepo.AddItems(ctx, tx, DeleteObjectQueue, keysToBeDeleted)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	var embeddingsToBeDeleted []string
	for _, fileID := range fileIDs {
		embeddingsToBeDeleted = append(embeddingsToBeDeleted, strconv.FormatInt(fileID, 10))
	}
	_, err = tx.ExecContext(ctx, `UPDATE file_data SET is_deleted = TRUE, pending_sync = TRUE WHERE file_id = ANY($1)`, pq.Array(fileIDs))
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	err = repo.QueueRepo.AddItems(ctx, tx, DeleteEmbeddingsQueue, embeddingsToBeDeleted)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	_, err = tx.ExecContext(ctx, `UPDATE object_keys SET is_deleted = TRUE WHERE file_id = ANY($1)`, pq.Array(fileIDs))
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return s3ObjectKeys, nil
}

func convertRowsToObjectKeys(rows *sql.Rows) ([]ente.S3ObjectKey, error) {
	defer rows.Close()
	fileObjectKeys := make([]ente.S3ObjectKey, 0)
	for rows.Next() {
		var fileObjectKey ente.S3ObjectKey
		err := rows.Scan(&fileObjectKey.FileID, &fileObjectKey.Type, &fileObjectKey.ObjectKey, &fileObjectKey.FileSize)
		if err != nil {
			return fileObjectKeys, stacktrace.Propagate(err, "")
		}
		fileObjectKeys = append(fileObjectKeys, fileObjectKey)
	}
	return fileObjectKeys, nil
}

// DoesObjectExist returns the true if there is an entry for the object key.
func (repo *ObjectRepository) DoesObjectExist(tx *sql.Tx, objectKey string) (bool, error) {
	var exists bool
	err := tx.QueryRow(
		`SELECT EXISTS (SELECT 1 FROM object_keys WHERE object_key = $1)`,
		objectKey).Scan(&exists)
	return exists, stacktrace.Propagate(err, "")
}

// DoesObjectOrTempObjectExist returns the true if there is an entry for the object key in
// either the object_keys or in temp_objects table.
func (repo *ObjectRepository) DoesObjectOrTempObjectExist(objectKey string) (bool, error) {
	var exists bool
	err := repo.DB.QueryRow(
		`SELECT (EXISTS (SELECT 1 FROM object_keys WHERE object_key = $1) OR
		         EXISTS (SELECT 1 FROM temp_objects WHERE object_key = $1))`,
		objectKey).Scan(&exists)
	return exists, stacktrace.Propagate(err, "")
}

// GetObjectState returns various bits of information about an object that are
// useful in pre-flight checks during replication.
//
// Unknown objects (i.e. objectKeys for which there are no entries) are
// considered as deleted.
func (repo *ObjectRepository) GetObjectState(objectKey string) (ObjectState ente.ObjectState, err error) {
	row := repo.DB.QueryRow(`
	SELECT ok.is_deleted, u.encrypted_email IS NULL AS is_user_deleted, ok.size
	FROM object_keys ok
	JOIN files f ON ok.file_id = f.file_id
	JOIN users u ON f.owner_id = u.user_id
	where object_key = $1
	`, objectKey)
	var os ente.ObjectState
	err = row.Scan(&os.IsFileDeleted, &os.IsUserDeleted, &os.Size)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			os.IsFileDeleted = true
			os.IsUserDeleted = true
			return os, nil
		}
		return os, stacktrace.Propagate(err, "Failed to fetch object state")
	}

	return os, nil
}
