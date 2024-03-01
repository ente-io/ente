package storagebonus

import (
	"database/sql"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/golang-migrate/migrate/v4"
	"github.com/golang-migrate/migrate/v4/database/postgres"
	log "github.com/sirupsen/logrus"
)

var db *sql.DB

func TestMain(m *testing.M) {
	if os.Getenv("ENV") != "test" {
		log.Fatalf("Not running tests in non-test environment")
		os.Exit(0)
	}
	err := setupDatabase()
	if err != nil {
		log.Fatalf("error setting up test database: %v", err)
	}
	db.QueryRow("DELETE FROM referral_codes")
	db.QueryRow("DELETE FROM storage_bonus")
	// Run the tests
	exitCode := m.Run()
	db.QueryRow("DELETE FROM referral_codes")
	db.QueryRow("DELETE FROM storage_bonus")
	// Close the test database connection
	err = db.Close()
	if err != nil {
		log.Fatalf("error closing test database connection: %v", err)
	}
	// Exit with the result of the tests
	os.Exit(exitCode)
}

func setupDatabase() error {
	var err error
	// Connect to the test database
	db, err = sql.Open("postgres", "user=test_user password=test_pass host=localhost dbname=ente_test_db sslmode=disable")
	if err != nil {
		log.Fatalf("error connecting to test database: %v", err)
	}
	driver, err := postgres.WithInstance(db, &postgres.Config{})
	if err != nil {
		log.Fatalf("error creating postgres driver: %v", err)
	}
	// Get the current working directory, find the path before "/pkg", and append "/migrations"
	cwd, _ := os.Getwd()
	cwd = strings.Split(cwd, "/pkg/")[0]
	configFilePath := "file://" + filepath.Join(cwd, "migrations")
	mig, err := migrate.NewWithDatabaseInstance(
		configFilePath, "ente_test_db", driver)
	if err != nil {
		log.Fatalf("error creating migrations: %v", err)
	} else {
		//log.Println("Loaded migration scripts")
		if err := mig.Up(); err != nil && err != migrate.ErrNoChange {
			log.Fatalf("error running migrations: %v", err)
		}
	}
	return err
}
