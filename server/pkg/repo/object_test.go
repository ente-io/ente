package repo

import (
	"database/sql"
	"testing"
)

func TestObjectLookupDBUsesLatencySensitiveDBWhenPresent(t *testing.T) {
	primaryDB := &sql.DB{}
	latencySensitiveDB := &sql.DB{}
	repository := &ObjectRepository{DB: primaryDB, LatencySensitiveDB: latencySensitiveDB}

	if got := repository.objectLookupDB(); got != latencySensitiveDB {
		t.Fatal("expected object lookup DB to use LatencySensitiveDB")
	}
}

func TestObjectLookupDBFallsBackToPrimaryDB(t *testing.T) {
	primaryDB := &sql.DB{}
	repository := &ObjectRepository{DB: primaryDB}

	if got := repository.objectLookupDB(); got != primaryDB {
		t.Fatal("expected object lookup DB to fall back to DB")
	}
}
