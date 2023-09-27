package pkg

import (
	"cli-go/internal/api"
	"cli-go/pkg/secrets"
	"fmt"
	bolt "go.etcd.io/bbolt"
)

type ClICtrl struct {
	Client    *api.Client
	DB        *bolt.DB
	KeyHolder *secrets.KeyHolder
}

func (c *ClICtrl) Init() error {
	return c.DB.Update(func(tx *bolt.Tx) error {
		_, err := tx.CreateBucketIfNotExists([]byte(AccBucket))
		if err != nil {
			return fmt.Errorf("create bucket: %s", err)
		}
		return nil
	})
}
