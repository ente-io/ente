package email

import (
	"database/sql"
	"testing"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/internal/testutil"
	"github.com/ente-io/museum/pkg/controller/lock"
	"github.com/ente-io/museum/pkg/repo"
	storageBonusRepo "github.com/ente-io/museum/pkg/repo/storagebonus"
	timeutil "github.com/ente-io/museum/pkg/utils/time"
)

const storageWarningIntegrationTestGiB = int64(1 << 30)

func TestSendStorageWarningMailsActiveOverageIntegration(t *testing.T) {
	testutil.WithServerRoot(t)

	db := testutil.RequireTestDB(t)
	testutil.ResetTables(t, db)
	t.Cleanup(func() {
		testutil.ResetTables(t, db)
	})

	now := timeutil.Microseconds()
	userID := testutil.InsertUser(t, db, testutil.UserFixture{
		Email:        "active-overage@ente.io",
		CreationTime: now - timeutil.MicroSecondsInOneHour,
	})
	testutil.InsertUsage(t, db, userID, 36*storageWarningIntegrationTestGiB)
	testutil.InsertSubscription(t, db, testutil.SubscriptionFixture{
		UserID:          userID,
		Storage:         10 * storageWarningIntegrationTestGiB,
		ExpiryTime:      now + 24*timeutil.MicroSecondsInOneHour,
		ProductID:       "photos_yearly",
		PaymentProvider: ente.Stripe,
	})

	controller := newStorageWarningIntegrationController(db)
	controller.SendStorageWarningMails()

	assertStorageWarningNotificationCount(t, db, userID, StorageWarningActiveOverageAnchorTemplateID, 1)
}

func TestSendStorageWarningMailsExpiredIntegration(t *testing.T) {
	testutil.WithServerRoot(t)

	db := testutil.RequireTestDB(t)
	testutil.ResetTables(t, db)
	t.Cleanup(func() {
		testutil.ResetTables(t, db)
	})

	now := timeutil.Microseconds()
	userID := testutil.InsertUser(t, db, testutil.UserFixture{
		Email:        "expired-subscription@ente.io",
		CreationTime: now - timeutil.MicroSecondsInOneHour,
	})
	testutil.InsertUsage(t, db, userID, 26*storageWarningIntegrationTestGiB)
	testutil.InsertSubscription(t, db, testutil.SubscriptionFixture{
		UserID:          userID,
		Storage:         10 * storageWarningIntegrationTestGiB,
		ExpiryTime:      now - storageWarningExpiredAnchorDelay - (10 * 24 * timeutil.MicroSecondsInOneHour),
		ProductID:       "photos_yearly",
		PaymentProvider: ente.Stripe,
	})

	controller := newStorageWarningIntegrationController(db)
	controller.SendStorageWarningMails()

	assertStorageWarningNotificationCount(t, db, userID, storageWarningExpired0TemplateID, 1)
}

func newStorageWarningIntegrationController(db *sql.DB) *EmailNotificationController {
	userRepo := &repo.UserRepository{
		DB:                  db,
		SecretEncryptionKey: testutil.SecretEncryptionKey(),
		HashingKey:          testutil.HashingKey(),
	}

	return &EmailNotificationController{
		UserRepo:         userRepo,
		UsageRepo:        &repo.UsageRepository{DB: db, UserRepo: userRepo},
		BillingRepo:      &repo.BillingRepository{DB: db},
		StorageBonusRepo: &storageBonusRepo.Repository{DB: db},
		LockController: &lock.LockController{
			TaskLockingRepo: &repo.TaskLockRepository{DB: db},
			HostName:        "storage-warning-test-host",
		},
		NotificationHistoryRepo: &repo.NotificationHistoryRepository{DB: db},
	}
}

func assertStorageWarningNotificationCount(t *testing.T, db *sql.DB, userID int64, templateID string, want int) {
	t.Helper()

	var got int
	err := db.QueryRow(
		`SELECT COUNT(*)
		   FROM notification_history
		  WHERE user_id = $1 AND template_id = $2`,
		userID,
		templateID,
	).Scan(&got)
	if err != nil {
		t.Fatalf("failed to count notification history for user %d template %q: %v", userID, templateID, err)
	}
	if got != want {
		t.Fatalf("unexpected notification count for user %d template %q: got %d want %d", userID, templateID, got, want)
	}
}
