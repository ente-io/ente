package pkg

import (
	"cli-go/internal/api"
	"fmt"
	bolt "go.etcd.io/bbolt"
)

type ClICtrl struct {
	Client *api.Client
	DB     *bolt.DB
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
