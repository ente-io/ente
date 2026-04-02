package datacleanup

import (
	"context"
	"database/sql"
	"testing"

	"github.com/ente-io/museum/internal/testutil"
)

func TestDeleteTableDataDeletesContactsAndAttachmentsForUser(t *testing.T) {
	testutil.WithServerRoot(t)

	db := testutil.RequireTestDB(t)
	testutil.ResetTables(t, db)
	t.Cleanup(func() {
		testutil.ResetTables(t, db)
	})

	targetUserID := testutil.InsertUser(t, db, testutil.UserFixture{
		UserID:       1,
		Email:        "target@ente.io",
		CreationTime: 1,
	})
	otherUserID := testutil.InsertUser(t, db, testutil.UserFixture{
		UserID:       2,
		Email:        "other@ente.io",
		CreationTime: 1,
	})

	mustExecCleanupTest(t, db,
		`INSERT INTO contact_entity(id, user_id, contact_user_id, encrypted_key, encrypted_data)
		 VALUES($1, $2, $3, $4, $5)`,
		"ct_target",
		targetUserID,
		otherUserID,
		[]byte("wrapped-key-target"),
		[]byte("payload-target"),
	)
	mustExecCleanupTest(t, db,
		`INSERT INTO contact_entity(id, user_id, contact_user_id, encrypted_key, encrypted_data)
		 VALUES($1, $2, $3, $4, $5)`,
		"ct_other",
		otherUserID,
		targetUserID,
		[]byte("wrapped-key-other"),
		[]byte("payload-other"),
	)
	mustExecCleanupTest(t, db,
		`INSERT INTO user_attachments(attachment_id, user_id, attachment_type, size, latest_bucket)
		 VALUES($1, $2, $3, $4, $5)`,
		"ua_target",
		targetUserID,
		"profile_picture",
		128,
		"b2-eu-cen",
	)
	mustExecCleanupTest(t, db,
		`INSERT INTO user_attachments(attachment_id, user_id, attachment_type, size, latest_bucket)
		 VALUES($1, $2, $3, $4, $5)`,
		"ua_other",
		otherUserID,
		"profile_picture",
		256,
		"b2-eu-cen",
	)

	repo := &Repository{DB: db}
	if err := repo.DeleteTableData(context.Background(), targetUserID); err != nil {
		t.Fatalf("DeleteTableData() error = %v", err)
	}

	assertCleanupRowCount(t, db, `SELECT COUNT(*) FROM contact_entity WHERE user_id = $1`, targetUserID, 0)
	assertCleanupRowCount(t, db, `SELECT COUNT(*) FROM user_attachments WHERE user_id = $1`, targetUserID, 0)
	assertCleanupRowCount(t, db, `SELECT COUNT(*) FROM contact_entity WHERE user_id = $1`, otherUserID, 1)
	assertCleanupRowCount(t, db, `SELECT COUNT(*) FROM user_attachments WHERE user_id = $1`, otherUserID, 1)
}

func mustExecCleanupTest(t *testing.T, db *sql.DB, query string, args ...any) {
	t.Helper()
	if _, err := db.Exec(query, args...); err != nil {
		t.Fatalf("exec failed for %q: %v", query, err)
	}
}

func assertCleanupRowCount(t *testing.T, db *sql.DB, query string, arg any, want int) {
	t.Helper()
	var got int
	if err := db.QueryRow(query, arg).Scan(&got); err != nil {
		t.Fatalf("query failed for %q: %v", query, err)
	}
	if got != want {
		t.Fatalf("row count for %q = %d, want %d", query, got, want)
	}
}
