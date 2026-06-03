package repo

import (
	"context"
	"database/sql"
	"encoding/base64"
	"fmt"
	"testing"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/internal/testutil"
)

func TestCleanupBadCollectionEntriesDryRun(t *testing.T) {
	repo, db := setupBadCollectionEntriesCleanupTest(t, 81)

	result, err := repo.CleanupBadCollectionEntries(context.Background(), false, false)
	if err != nil {
		t.Fatalf("CleanupBadCollectionEntries dry-run error = %v", err)
	}
	if result.CollectionFilesWouldDelete != 3 || result.CollectionFilesDeleted != 0 {
		t.Fatalf("unexpected file counts: %+v", result)
	}
	if result.CollectionSharesWouldDelete != 2 || result.CollectionSharesDeleted != 0 {
		t.Fatalf("unexpected share counts: %+v", result)
	}
	for _, fileID := range badCollectionFileIDs {
		if cleanupCollectionFileDeleted(t, db, badCollectionFilesCollectionID, fileID) {
			t.Fatalf("file %d was deleted during dry-run", fileID)
		}
	}
	for _, share := range badCollectionShares {
		if cleanupCollectionShareDeleted(t, db, share.collectionID, share.fromUserID, share.toUserID) {
			t.Fatalf("share %+v was deleted during dry-run", share)
		}
	}
}

func TestCleanupBadCollectionEntriesAppliesFileFlagOnly(t *testing.T) {
	repo, db := setupBadCollectionEntriesCleanupTest(t, 81)

	result, err := repo.CleanupBadCollectionEntries(context.Background(), true, false)
	if err != nil {
		t.Fatalf("CleanupBadCollectionEntries file apply error = %v", err)
	}
	if result.CollectionFilesDeleted != 3 || result.CollectionFilesWouldDelete != 0 {
		t.Fatalf("unexpected file counts: %+v", result)
	}
	if result.CollectionSharesDeleted != 0 || result.CollectionSharesWouldDelete != 2 {
		t.Fatalf("unexpected share counts: %+v", result)
	}
	for _, fileID := range badCollectionFileIDs[:3] {
		if !cleanupCollectionFileDeleted(t, db, badCollectionFilesCollectionID, fileID) {
			t.Fatalf("file %d was not deleted", fileID)
		}
	}
	if cleanupCollectionFileDeleted(t, db, badCollectionFilesCollectionID, badCollectionFileIDs[3]) {
		t.Fatalf("file without active alternate collection was deleted")
	}
	for _, share := range badCollectionShares {
		if cleanupCollectionShareDeleted(t, db, share.collectionID, share.fromUserID, share.toUserID) {
			t.Fatalf("share %+v was deleted by file-only cleanup", share)
		}
	}
	if cleanupCollectionUpdationTime(t, db, badCollectionFilesCollectionID) <= 1 {
		t.Fatal("file collection updation_time was not bumped")
	}
}

func TestCleanupBadCollectionEntriesAppliesShareFlagOnlyAndSkipsValidKey(t *testing.T) {
	repo, db := setupBadCollectionEntriesCleanupTest(t, sealedCollectionKeyLen)

	result, err := repo.CleanupBadCollectionEntries(context.Background(), false, true)
	if err != nil {
		t.Fatalf("CleanupBadCollectionEntries share apply error = %v", err)
	}
	if result.CollectionSharesDeleted != 1 || result.CollectionSharesWouldDelete != 0 {
		t.Fatalf("unexpected share counts: %+v", result)
	}
	if result.CollectionFilesDeleted != 0 || result.CollectionFilesWouldDelete != 3 {
		t.Fatalf("unexpected file counts: %+v", result)
	}

	badShare := badCollectionShares[0]
	if !cleanupCollectionShareDeleted(t, db, badShare.collectionID, badShare.fromUserID, badShare.toUserID) {
		t.Fatal("invalid share was not deleted")
	}
	validShare := badCollectionShares[1]
	if cleanupCollectionShareDeleted(t, db, validShare.collectionID, validShare.fromUserID, validShare.toUserID) {
		t.Fatal("valid sealed-key share was deleted")
	}
	for _, fileID := range badCollectionFileIDs {
		if cleanupCollectionFileDeleted(t, db, badCollectionFilesCollectionID, fileID) {
			t.Fatalf("file %d was deleted by share-only cleanup", fileID)
		}
	}
	if cleanupCollectionUpdationTime(t, db, badShare.collectionID) <= 1 {
		t.Fatal("bad share collection updation_time was not bumped")
	}
	if cleanupCollectionUpdationTime(t, db, validShare.collectionID) != 1 {
		t.Fatal("valid share collection updation_time was bumped")
	}
}

func setupBadCollectionEntriesCleanupTest(t *testing.T, secondShareKeyLen int) (*CollectionRepository, *sql.DB) {
	t.Helper()
	testutil.WithServerRoot(t)
	db := testutil.RequireTestDB(t)
	testutil.ResetTables(t, db)
	t.Cleanup(func() {
		testutil.ResetTables(t, db)
	})

	userIDs := []int64{
		1001,
		1580559962588538,
		1580559962407419,
		1580559962649891,
		1580559962653442,
	}
	for _, userID := range userIDs {
		testutil.InsertUser(t, db, testutil.UserFixture{
			UserID:       userID,
			Email:        fmt.Sprintf("cleanup-%d@ente.com", userID),
			CreationTime: 1,
		})
	}

	insertCleanupCollection(t, db, badCollectionFilesCollectionID, 1001)
	insertCleanupCollection(t, db, badCollectionFilesCollectionID+1, 1001)
	insertCleanupCollection(t, db, badCollectionShares[0].collectionID, badCollectionShares[0].fromUserID)
	insertCleanupCollection(t, db, badCollectionShares[1].collectionID, badCollectionShares[1].fromUserID)

	for idx, fileID := range badCollectionFileIDs {
		insertCleanupFile(t, db, fileID, 1001)
		insertCleanupCollectionFile(t, db, badCollectionFilesCollectionID, fileID, 1001)
		if idx < 3 {
			insertCleanupCollectionFile(t, db, badCollectionFilesCollectionID+1, fileID, 1001)
		}
	}

	insertCleanupCollectionShare(t, db, badCollectionShares[0], 79)
	insertCleanupCollectionShare(t, db, badCollectionShares[1], secondShareKeyLen)

	return &CollectionRepository{DB: db}, db
}

func insertCleanupCollection(t *testing.T, db *sql.DB, collectionID int64, ownerID int64) {
	t.Helper()
	_, err := db.Exec(
		`INSERT INTO collections(collection_id, owner_id, encrypted_key, key_decryption_nonce, name, type, attributes, updation_time, app)
		 OVERRIDING SYSTEM VALUE
		 VALUES($1, $2, $3, $4, $5, $6, $7::jsonb, $8, $9)`,
		collectionID,
		ownerID,
		"encrypted-key",
		"key-nonce",
		"Cleanup collection",
		"album",
		"{}",
		int64(1),
		string(ente.Photos),
	)
	if err != nil {
		t.Fatalf("failed to insert collection %d: %v", collectionID, err)
	}
}

func insertCleanupFile(t *testing.T, db *sql.DB, fileID int64, ownerID int64) {
	t.Helper()
	_, err := db.Exec(
		`INSERT INTO files(file_id, owner_id, file_decryption_header, thumbnail_decryption_header, metadata_decryption_header, encrypted_metadata, updation_time, info)
		 VALUES($1, $2, $3, $4, $5, $6, $7, $8::jsonb)`,
		fileID,
		ownerID,
		"file-header",
		"thumbnail-header",
		"metadata-header",
		"encrypted-metadata",
		int64(1),
		"{}",
	)
	if err != nil {
		t.Fatalf("failed to insert file %d: %v", fileID, err)
	}
}

func insertCleanupCollectionFile(t *testing.T, db *sql.DB, collectionID int64, fileID int64, ownerID int64) {
	t.Helper()
	_, err := db.Exec(
		`INSERT INTO collection_files(collection_id, file_id, encrypted_key, key_decryption_nonce, updation_time, c_owner_id, f_owner_id)
		 VALUES($1, $2, $3, $4, $5, $6, $7)`,
		collectionID,
		fileID,
		"collection-file-key",
		"collection-file-nonce",
		int64(1),
		ownerID,
		ownerID,
	)
	if err != nil {
		t.Fatalf("failed to insert collection file %d/%d: %v", collectionID, fileID, err)
	}
}

func insertCleanupCollectionShare(t *testing.T, db *sql.DB, share badCollectionShare, keyLen int) {
	t.Helper()
	_, err := db.Exec(
		`INSERT INTO collection_shares(collection_id, from_user_id, to_user_id, encrypted_key, updation_time, role_type, shared_at)
		 VALUES($1, $2, $3, $4, $5, $6, $7)`,
		share.collectionID,
		share.fromUserID,
		share.toUserID,
		base64.StdEncoding.EncodeToString(make([]byte, keyLen)),
		int64(1),
		string(ente.VIEWER),
		int64(1),
	)
	if err != nil {
		t.Fatalf("failed to insert collection share %+v: %v", share, err)
	}
}

func cleanupCollectionFileDeleted(t *testing.T, db *sql.DB, collectionID int64, fileID int64) bool {
	t.Helper()
	var isDeleted bool
	err := db.QueryRow(`SELECT is_deleted FROM collection_files WHERE collection_id = $1 AND file_id = $2`, collectionID, fileID).Scan(&isDeleted)
	if err != nil {
		t.Fatalf("failed to fetch collection file %d/%d: %v", collectionID, fileID, err)
	}
	return isDeleted
}

func cleanupCollectionShareDeleted(t *testing.T, db *sql.DB, collectionID int64, fromUserID int64, toUserID int64) bool {
	t.Helper()
	var isDeleted bool
	err := db.QueryRow(`SELECT is_deleted FROM collection_shares WHERE collection_id = $1 AND from_user_id = $2 AND to_user_id = $3`, collectionID, fromUserID, toUserID).Scan(&isDeleted)
	if err != nil {
		t.Fatalf("failed to fetch collection share %d/%d/%d: %v", collectionID, fromUserID, toUserID, err)
	}
	return isDeleted
}

func cleanupCollectionUpdationTime(t *testing.T, db *sql.DB, collectionID int64) int64 {
	t.Helper()
	var updationTime int64
	err := db.QueryRow(`SELECT updation_time FROM collections WHERE collection_id = $1`, collectionID).Scan(&updationTime)
	if err != nil {
		t.Fatalf("failed to fetch collection %d updation_time: %v", collectionID, err)
	}
	return updationTime
}
