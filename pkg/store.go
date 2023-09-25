package pkg

import (
	"cli-go/pkg/model"
	"context"
	"fmt"
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

func (c *ClICtrl) GetConfigValue(ctx context.Context, key string) ([]byte, error) {
	var value []byte
	err := c.DB.View(func(tx *bolt.Tx) error {
		kvBucket, err := getAccountStore(ctx, tx, model.KVConfig)
		if err != nil {
			return err
		}
		value = kvBucket.Get([]byte(key))
		return nil
	})
	return value, err
}

func (c *ClICtrl) PutConfigValue(ctx context.Context, key string, value []byte) error {
	return c.DB.Update(func(tx *bolt.Tx) error {
		kvBucket, err := getAccountStore(ctx, tx, model.KVConfig)
		if err != nil {
			return err
		}
		return kvBucket.Put([]byte(key), value)
	})
}
func (c *ClICtrl) PutValue(ctx context.Context, store model.PhotosStore, key []byte, value []byte) error {
	return c.DB.Update(func(tx *bolt.Tx) error {
		kvBucket, err := getAccountStore(ctx, tx, store)
		if err != nil {
			return err
		}
		return kvBucket.Put(key, value)
	})
}

func getAccountStore(ctx context.Context, tx *bolt.Tx, storeType model.PhotosStore) (*bolt.Bucket, error) {
	accountId := ctx.Value("account_id").(string)
	accountBucket := tx.Bucket([]byte(accountId))
	if accountBucket == nil {
		return nil, fmt.Errorf("account bucket not found")
	}
	store := accountBucket.Bucket([]byte(storeType))
	if store == nil {
		return nil, fmt.Errorf("store %s not found", storeType)
	}
	return store, nil
}
