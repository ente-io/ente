package user

import (
	"context"
	"database/sql"
	"net/http/httptest"
	"testing"

	"github.com/ente-io/museum/ente"
	contactmodel "github.com/ente-io/museum/ente/contact"
	cleanupentity "github.com/ente-io/museum/ente/data_cleanup"
	"github.com/ente-io/museum/internal/testutil"
	"github.com/ente-io/museum/pkg/repo"
	contactrepo "github.com/ente-io/museum/pkg/repo/contact"
	cleanuprepo "github.com/ente-io/museum/pkg/repo/datacleanup"
	"github.com/ente-io/museum/pkg/utils/config"
	"github.com/gin-gonic/gin"
	"github.com/spf13/viper"
)

func TestHandleAccountRecoveryTouchesContactsForResolvedEmailSync(t *testing.T) {
	testutil.WithServerRoot(t)
	viper.Reset()
	if err := config.ConfigureViper("local"); err != nil {
		t.Fatalf("failed to configure viper: %v", err)
	}
	t.Cleanup(viper.Reset)

	db := testutil.RequireTestDB(t)
	testutil.ResetTables(t, db)
	t.Cleanup(func() {
		testutil.ResetTables(t, db)
	})

	ownerID := testutil.InsertUser(t, db, testutil.UserFixture{
		UserID:       1,
		Email:        "owner@ente.com",
		CreationTime: 1,
	})
	contactUserID := testutil.InsertUser(t, db, testutil.UserFixture{
		UserID:       82,
		Email:        "before-recovery@ente.com",
		CreationTime: 1,
	})

	insertKeyAttributes(t, db, contactUserID)
	insertScheduledDelete(t, db, contactUserID)

	objectCleanupRepo := &repo.ObjectCleanupRepository{DB: db}
	contactsRepo := &contactrepo.Repository{
		DB:                  db,
		ObjectCleanupRepo:   objectCleanupRepo,
		SecretEncryptionKey: testutil.SecretEncryptionKey(),
	}
	contactID, err := contactsRepo.Create(context.Background(), ownerID, contactmodel.CreateRequest{
		ContactUserID: contactUserID,
		EncryptedKey:  []byte("wrapped-key"),
		EncryptedData: []byte("payload"),
	})
	if err != nil {
		t.Fatalf("failed to create contact: %v", err)
	}
	created, err := contactsRepo.Get(context.Background(), ownerID, contactID)
	if err != nil {
		t.Fatalf("failed to fetch created contact: %v", err)
	}
	if created.Email == nil || *created.Email != "before-recovery@ente.com" {
		t.Fatalf("unexpected initial email: %v", created.Email)
	}

	userRepo := &repo.UserRepository{
		DB:                  db,
		SecretEncryptionKey: testutil.SecretEncryptionKey(),
		HashingKey:          testutil.HashingKey(),
	}
	if err := userRepo.Delete(contactUserID); err != nil {
		t.Fatalf("failed to soft-delete contact user: %v", err)
	}

	gin.SetMode(gin.TestMode)
	recorder := httptest.NewRecorder()
	ctx, _ := gin.CreateTestContext(recorder)
	ctx.Request = httptest.NewRequest("POST", "/", nil)
	ctx.Set("req_id", "recovery-test")

	controller := &UserController{
		UserRepo:            userRepo,
		DataCleanupRepo:     &cleanuprepo.Repository{DB: db},
		ContactRepo:         contactsRepo,
		SecretEncryptionKey: testutil.SecretEncryptionKey(),
		HashingKey:          testutil.HashingKey(),
	}

	if err := controller.HandleAccountRecovery(ctx, ente.RecoverAccountRequest{
		UserID:  contactUserID,
		EmailID: "after-recovery@ente.com",
	}); err != nil {
		t.Fatalf("HandleAccountRecovery() error = %v", err)
	}

	diff, err := contactsRepo.GetDiff(context.Background(), ownerID, created.UpdatedAt, 10)
	if err != nil {
		t.Fatalf("GetDiff() error = %v", err)
	}
	if len(diff) != 1 {
		t.Fatalf("diff length = %d, want 1", len(diff))
	}
	if diff[0].Email == nil || *diff[0].Email != "after-recovery@ente.com" {
		t.Fatalf("resolved email after recovery = %v, want updated email", diff[0].Email)
	}
}

func insertKeyAttributes(t *testing.T, db *sql.DB, userID int64) {
	t.Helper()
	_, err := db.Exec(
		`INSERT INTO key_attributes(
			user_id, kek_salt, kek_hash_bytes, encrypted_key, key_decryption_nonce,
			public_key, encrypted_secret_key, secret_key_decryption_nonce, mem_limit, ops_limit
		) VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
		userID,
		"kek-salt",
		[]byte("kek-hash"),
		"encrypted-key",
		"key-nonce",
		"public-key",
		"encrypted-secret-key",
		"secret-key-nonce",
		int64(67108864),
		int64(2),
	)
	if err != nil {
		t.Fatalf("failed to insert key_attributes for user %d: %v", userID, err)
	}
}

func insertScheduledDelete(t *testing.T, db *sql.DB, userID int64) {
	t.Helper()
	_, err := db.Exec(
		`INSERT INTO data_cleanup(user_id, stage, stage_schedule_time, stage_attempt_count)
		 VALUES($1, $2, $3, $4)`,
		userID,
		cleanupentity.Scheduled,
		int64(1),
		0,
	)
	if err != nil {
		t.Fatalf("failed to insert scheduled delete row for user %d: %v", userID, err)
	}
}
