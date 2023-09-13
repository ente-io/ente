package pkg

import (
	"log"
	"time"

	bolt "go.etcd.io/bbolt"
)

func GetDB(path string) (*bolt.DB, error) {
	db, err := bolt.Open(path, 0600, &bolt.Options{Timeout: 1 * time.Second})
	if err != nil {
		log.Fatal(err)
	}
	return db, err
}
