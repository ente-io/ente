package kex

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"time"

	log "github.com/sirupsen/logrus"

	time_util "github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
)

const (
	// KexStorageTTL is the time to live for a key exchange key
	KexStorageTTLInMinutes = 60
)

type Repository struct {
	DB *sql.DB
}

// AddKey adds a wrapped key to KeyDB for retrieval withiin KexStorageTTL
func (r *Repository) AddKey(wrappedKey string, customIdentifier string) (identifier string, err error) {

	if customIdentifier != "" {
		identifier = customIdentifier
	} else {
		// generate a random identifier
		randomData := make([]byte, 8)
		_, err = rand.Read(randomData)
		if err != nil {
			return "", err
		}
		identifier = hex.EncodeToString(randomData)
	}

	// add to sql under "kex_store" table
	_, err = r.DB.Exec("INSERT INTO kex_store (id, wrapped_key, added_at) VALUES ($1, $2, $3)", identifier, wrappedKey, time_util.Microseconds())
	if err != nil {
		return "", err
	}

	return
}

// GetKey returns the wrapped key with an identifier and user ID and deletes it from KeyDB
func (r *Repository) GetKey(identifier string) (wrappedKey string, err error) {

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// get the wrapped key from sql
	row := r.DB.QueryRowContext(ctx, "SELECT wrapped_key FROM kex_store WHERE id = $1", identifier)

	err = row.Scan(&wrappedKey)

	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}

	// delete the key from sql
	go r.DB.Exec("DELETE FROM kex_store WHERE id = $1", identifier)

	return
}

func (r *Repository) DeleteOldKeys() {
	// go through keys where added_at < now - KexStorageTTL and delete them
	breakTime := time_util.MicrosecondsBeforeMinutes(KexStorageTTLInMinutes)
	_, err := r.DB.Exec("DELETE FROM kex_store WHERE added_at < $1", breakTime)
	if err != nil {
		log.Errorf("Error deleting old keys: %v", err)
		return
	}

	log.Infof("Deleted old keys less than %v old", breakTime)
}
