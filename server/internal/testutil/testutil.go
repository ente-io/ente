package testutil

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"testing"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/crypto"
	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	_ "github.com/lib/pq"
)

const testDBDSN = "user=test_user password=test_pass host=localhost dbname=ente_test_db sslmode=disable"
const testDBName = "ente_test_db"
const testDBUser = "test_user"
const testDBSentinelTable = "ente_test_db_sentinel"
const testDBSentinelMarker = "ente-server-test-db-v1"

var (
	testDBInitOnce sync.Once
	testDB         *sql.DB
	testDBErr      error
	serverRootOnce sync.Once
	serverRoot     string
	serverRootErr  error
	serverRootMu   sync.Mutex
)

var (
	testSecretEncryptionKey = []byte("0123456789abcdef0123456789abcdef")
	testHashingKey          = []byte("abcdef0123456789abcdef0123456789")
)

type UserFixture struct {
	UserID        int64
	Email         string
	CreationTime  int64
	FamilyAdminID *int64
}

type SubscriptionFixture struct {
	UserID                int64
	Storage               int64
	OriginalTransactionID string
	ExpiryTime            int64
	ProductID             string
	PaymentProvider       ente.PaymentProvider
	Attributes            string
}

type NotificationHistoryFixture struct {
	UserID            int64
	TemplateID        string
	SentTime          int64
	NotificationGroup string
}

func RequireTestDB(t *testing.T) *sql.DB {
	t.Helper()
	if os.Getenv("ENV") != "test" {
		t.Skip("requires ENV=test")
	}

	testDBInitOnce.Do(func() {
		testDB, testDBErr = sql.Open("postgres", testDBDSN)
		if testDBErr != nil {
			return
		}
		if err := testDB.Ping(); err != nil {
			testDBErr = err
			return
		}
		if err := verifySafeTestDB(testDB); err != nil {
			testDBErr = err
			return
		}

		driver, err := postgres.WithInstance(testDB, &postgres.Config{})
		if err != nil {
			testDBErr = err
			return
		}

		migrationPath := "file://" + filepath.Join(serverRootPath())
		migrationPath = migrationPath + "/migrations"
		mig, err := migrate.NewWithDatabaseInstance(migrationPath, "ente_test_db", driver)
		if err != nil {
			testDBErr = err
			return
		}
		if err := mig.Up(); err != nil && err != migrate.ErrNoChange {
			testDBErr = err
			return
		}
	})

	if testDBErr != nil {
		t.Fatalf("test database setup failed: %v", testDBErr)
	}
	return testDB
}

func ResetTables(t *testing.T, db *sql.DB) {
	t.Helper()
	if err := verifySafeTestDB(db); err != nil {
		t.Fatalf("refusing to reset tables on unsafe database connection: %v", err)
	}
	_, err := db.Exec(`
		TRUNCATE TABLE
			notification_history,
			task_lock,
			storage_bonus,
			referral_codes,
			subscriptions,
			usage,
			families,
			tokens,
			temp_objects,
			user_attachments,
			contact_entity,
			entity_data,
			entity_key,
			authenticator_entity,
			collections,
			users
		RESTART IDENTITY CASCADE`)
	if err != nil {
		t.Fatalf("failed to reset test tables: %v", err)
	}
}

func verifySafeTestDB(db *sql.DB) error {
	var currentDBName, currentDBUser string
	err := db.QueryRow(`SELECT current_database(), current_user`).Scan(&currentDBName, &currentDBUser)
	if err != nil {
		return fmt.Errorf("failed to verify test database identity: %w", err)
	}
	if currentDBName != testDBName {
		return fmt.Errorf("expected test database %q, connected to %q", testDBName, currentDBName)
	}
	if currentDBUser != testDBUser {
		return fmt.Errorf("expected test database user %q, connected as %q", testDBUser, currentDBUser)
	}
	var marker string
	err = db.QueryRow(fmt.Sprintf(`SELECT marker FROM public.%s WHERE id = 1`, testDBSentinelTable)).Scan(&marker)
	if err != nil {
		return fmt.Errorf("missing test database sentinel in %q: run ./scripts/setup-test-db.sh or use the docker test runner: %w", testDBName, err)
	}
	if marker != testDBSentinelMarker {
		return fmt.Errorf("unexpected test database sentinel marker %q", marker)
	}
	return nil
}

func WithServerRoot(t *testing.T) {
	t.Helper()
	serverRootMu.Lock()

	originalWD, err := os.Getwd()
	if err != nil {
		serverRootMu.Unlock()
		t.Fatalf("failed to get cwd: %v", err)
	}
	if err := os.Chdir(serverRootPath()); err != nil {
		serverRootMu.Unlock()
		t.Fatalf("failed to chdir to server root: %v", err)
	}

	t.Cleanup(func() {
		if err := os.Chdir(originalWD); err != nil {
			t.Errorf("failed to restore cwd: %v", err)
		}
		serverRootMu.Unlock()
	})
}

func SecretEncryptionKey() []byte {
	return append([]byte(nil), testSecretEncryptionKey...)
}

func HashingKey() []byte {
	return append([]byte(nil), testHashingKey...)
}

func InsertUser(t *testing.T, db *sql.DB, fixture UserFixture) int64 {
	t.Helper()
	if fixture.Email == "" {
		t.Fatal("user fixture email is required")
	}
	if fixture.CreationTime == 0 {
		t.Fatal("user fixture creation_time is required")
	}

	normalizedEmail := strings.ToLower(strings.TrimSpace(fixture.Email))
	encryptedEmail, err := crypto.Encrypt(normalizedEmail, testSecretEncryptionKey)
	if err != nil {
		t.Fatalf("failed to encrypt email %q: %v", fixture.Email, err)
	}
	emailHash, err := crypto.GetHash(normalizedEmail, testHashingKey)
	if err != nil {
		t.Fatalf("failed to hash email %q: %v", fixture.Email, err)
	}

	if fixture.UserID > 0 {
		_, err = db.Exec(
			`INSERT INTO users(user_id, encrypted_email, email_decryption_nonce, email_hash, creation_time, family_admin_id)
			 OVERRIDING SYSTEM VALUE
			 VALUES($1, $2, $3, $4, $5, $6)`,
			fixture.UserID,
			encryptedEmail.Cipher,
			encryptedEmail.Nonce,
			emailHash,
			fixture.CreationTime,
			fixture.FamilyAdminID,
		)
		if err != nil {
			t.Fatalf("failed to insert user %q: %v", fixture.Email, err)
		}
		return fixture.UserID
	}

	var userID int64
	err = db.QueryRow(
		`INSERT INTO users(encrypted_email, email_decryption_nonce, email_hash, creation_time, family_admin_id)
		 VALUES($1, $2, $3, $4, $5)
		 RETURNING user_id`,
		encryptedEmail.Cipher,
		encryptedEmail.Nonce,
		emailHash,
		fixture.CreationTime,
		fixture.FamilyAdminID,
	).Scan(&userID)
	if err != nil {
		t.Fatalf("failed to insert user %q: %v", fixture.Email, err)
	}
	return userID
}

func InsertUsage(t *testing.T, db *sql.DB, userID int64, storageConsumed int64) {
	t.Helper()
	_, err := db.Exec(`INSERT INTO usage(user_id, storage_consumed) VALUES($1, $2)`, userID, storageConsumed)
	if err != nil {
		t.Fatalf("failed to insert usage for user %d: %v", userID, err)
	}
}

func InsertSubscription(t *testing.T, db *sql.DB, fixture SubscriptionFixture) {
	t.Helper()
	if fixture.UserID == 0 {
		t.Fatal("subscription fixture user_id is required")
	}
	if fixture.Storage == 0 {
		t.Fatal("subscription fixture storage is required")
	}
	if fixture.OriginalTransactionID == "" {
		fixture.OriginalTransactionID = fmt.Sprintf("txn-%d", fixture.UserID)
	}
	if fixture.ProductID == "" {
		fixture.ProductID = "photos_yearly"
	}
	if fixture.PaymentProvider == "" {
		fixture.PaymentProvider = ente.Stripe
	}
	if fixture.Attributes == "" {
		fixture.Attributes = "{}"
	}

	_, err := db.Exec(
		`INSERT INTO subscriptions(user_id, storage, original_transaction_id, expiry_time, product_id, payment_provider, latest_verification_data, attributes)
		 VALUES($1, $2, $3, $4, $5, $6, $7, $8::jsonb)`,
		fixture.UserID,
		fixture.Storage,
		fixture.OriginalTransactionID,
		fixture.ExpiryTime,
		fixture.ProductID,
		fixture.PaymentProvider,
		"",
		fixture.Attributes,
	)
	if err != nil {
		t.Fatalf("failed to insert subscription for user %d: %v", fixture.UserID, err)
	}
}

func InsertNotificationHistory(t *testing.T, db *sql.DB, fixture NotificationHistoryFixture) {
	t.Helper()
	if fixture.UserID == 0 {
		t.Fatal("notification history fixture user_id is required")
	}
	if fixture.TemplateID == "" {
		t.Fatal("notification history fixture template_id is required")
	}
	if fixture.SentTime == 0 {
		t.Fatal("notification history fixture sent_time is required")
	}

	var notificationGroup sql.NullString
	if fixture.NotificationGroup != "" {
		notificationGroup = sql.NullString{
			String: fixture.NotificationGroup,
			Valid:  true,
		}
	}

	_, err := db.Exec(
		`INSERT INTO notification_history(user_id, template_id, sent_time, notification_group)
		 VALUES($1, $2, $3, $4)`,
		fixture.UserID,
		fixture.TemplateID,
		fixture.SentTime,
		notificationGroup,
	)
	if err != nil {
		t.Fatalf("failed to insert notification history for user %d: %v", fixture.UserID, err)
	}
}

func serverRootPath() string {
	serverRootOnce.Do(func() {
		_, file, _, ok := runtime.Caller(0)
		if !ok {
			serverRootErr = fmt.Errorf("failed to resolve runtime caller for testutil")
			return
		}
		serverRoot = filepath.Clean(filepath.Join(filepath.Dir(file), "..", ".."))
	})
	if serverRootErr != nil {
		panic(serverRootErr)
	}
	return serverRoot
}
