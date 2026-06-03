package repo

import (
	"context"
	"database/sql"
	"encoding/base64"

	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/lib/pq"
)

const (
	badCollectionFilesCollectionID = 1580559966740107
	sealedCollectionKeyLen         = 80
)

var badCollectionFileIDs = []int64{588219655, 588220428, 588220482, 588220590}

type badCollectionShare struct {
	collectionID int64
	fromUserID   int64
	toUserID     int64
}

var badCollectionShares = []badCollectionShare{
	{collectionID: 1580559964131155, fromUserID: 1580559962588538, toUserID: 1580559962407419},
	{collectionID: 1580559966298981, fromUserID: 1580559962649891, toUserID: 1580559962653442},
}

type BadCollectionEntriesCleanupResult struct {
	CollectionFilesDeleted      int64 `json:"collectionFilesDeleted"`
	CollectionFilesWouldDelete  int64 `json:"collectionFilesWouldDelete"`
	CollectionSharesDeleted     int64 `json:"collectionSharesDeleted"`
	CollectionSharesWouldDelete int64 `json:"collectionSharesWouldDelete"`
}

func (repo *CollectionRepository) CleanupBadCollectionEntries(ctx context.Context, applyFiles bool, applyShares bool) (BadCollectionEntriesCleanupResult, error) {
	var result BadCollectionEntriesCleanupResult
	now := time.Microseconds()
	touchedCollections := make(map[int64]bool)

	tx, err := repo.DB.BeginTx(ctx, nil)
	if err != nil {
		return result, stacktrace.Propagate(err, "")
	}
	defer tx.Rollback()

	fileCount, err := cleanupBadCollectionFiles(ctx, tx, now, applyFiles)
	if err != nil {
		return result, stacktrace.Propagate(err, "")
	}
	if applyFiles {
		result.CollectionFilesDeleted = fileCount
	} else {
		result.CollectionFilesWouldDelete = fileCount
	}
	if fileCount > 0 && applyFiles {
		touchedCollections[badCollectionFilesCollectionID] = true
	}

	shareCount, shareCollections, err := cleanupBadCollectionShares(ctx, tx, now, applyShares)
	if err != nil {
		return result, stacktrace.Propagate(err, "")
	}
	if applyShares {
		result.CollectionSharesDeleted = shareCount
	} else {
		result.CollectionSharesWouldDelete = shareCount
	}
	if shareCount > 0 && applyShares {
		for collectionID := range shareCollections {
			touchedCollections[collectionID] = true
		}
	}

	for collectionID := range touchedCollections {
		if _, err := tx.ExecContext(ctx, `UPDATE collections SET updation_time = $1 WHERE collection_id = $2`, now, collectionID); err != nil {
			return result, stacktrace.Propagate(err, "")
		}
	}

	return result, stacktrace.Propagate(tx.Commit(), "")
}

func cleanupBadCollectionFiles(ctx context.Context, tx *sql.Tx, updationTime int64, apply bool) (int64, error) {
	if !apply {
		var count int64
		err := tx.QueryRowContext(ctx, `
			SELECT count(*)
			FROM collection_files cf
			WHERE cf.collection_id = $1
				AND cf.file_id = ANY($2)
				AND cf.is_deleted = false
				AND EXISTS (
					SELECT 1
					FROM collection_files other_cf
					WHERE other_cf.file_id = cf.file_id
						AND other_cf.collection_id <> cf.collection_id
						AND other_cf.is_deleted = false
				)`,
			badCollectionFilesCollectionID, pq.Array(badCollectionFileIDs)).Scan(&count)
		return count, stacktrace.Propagate(err, "")
	}

	res, err := tx.ExecContext(ctx, `
		UPDATE collection_files cf
		SET is_deleted = true, updation_time = $1
		WHERE cf.collection_id = $2
			AND cf.file_id = ANY($3)
			AND cf.is_deleted = false
			AND EXISTS (
				SELECT 1
				FROM collection_files other_cf
				WHERE other_cf.file_id = cf.file_id
					AND other_cf.collection_id <> cf.collection_id
					AND other_cf.is_deleted = false
			)`,
		updationTime, badCollectionFilesCollectionID, pq.Array(badCollectionFileIDs))
	if err != nil {
		return 0, stacktrace.Propagate(err, "")
	}
	count, err := res.RowsAffected()
	return count, stacktrace.Propagate(err, "")
}

func cleanupBadCollectionShares(ctx context.Context, tx *sql.Tx, updationTime int64, apply bool) (int64, map[int64]bool, error) {
	var count int64
	touchedCollections := make(map[int64]bool)
	for _, share := range badCollectionShares {
		var encryptedKey string
		err := tx.QueryRowContext(ctx, `
			SELECT encrypted_key
			FROM collection_shares
			WHERE collection_id = $1
				AND from_user_id = $2
				AND to_user_id = $3
				AND is_deleted = false`,
			share.collectionID, share.fromUserID, share.toUserID).Scan(&encryptedKey)
		if err == sql.ErrNoRows {
			continue
		}
		if err != nil {
			return 0, nil, stacktrace.Propagate(err, "")
		}
		decoded, err := base64.StdEncoding.DecodeString(encryptedKey)
		if err != nil || len(decoded) == sealedCollectionKeyLen {
			continue
		}
		if !apply {
			count++
			continue
		}
		res, err := tx.ExecContext(ctx, `
			UPDATE collection_shares
			SET is_deleted = true, updation_time = $1
			WHERE collection_id = $2
				AND from_user_id = $3
				AND to_user_id = $4
				AND is_deleted = false`,
			updationTime, share.collectionID, share.fromUserID, share.toUserID)
		if err != nil {
			return 0, nil, stacktrace.Propagate(err, "")
		}
		affected, err := res.RowsAffected()
		if err != nil {
			return 0, nil, stacktrace.Propagate(err, "")
		}
		count += affected
		if affected > 0 {
			touchedCollections[share.collectionID] = true
		}
	}
	return count, touchedCollections, nil
}
