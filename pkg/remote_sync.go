package pkg

import (
	"cli-go/pkg/model"
	"context"
	"encoding/base64"
	"fmt"
	bolt "go.etcd.io/bbolt"
	"log"
)

func (c *ClICtrl) SyncAccount(account model.Account) error {
	secretInfo, err := c.KeyHolder.LoadSecrets(account, c.CliKey)
	if err != nil {
		return err
	}
	ctx := c.buildRequestContext(context.Background(), account)
	err = createDataBuckets(c.DB, account)
	if err != nil {
		return err
	}
	c.Client.AddToken(account.AccountKey(), base64.URLEncoding.EncodeToString(secretInfo.Token))
	err = c.fetchRemoteCollections(ctx)
	if err != nil {
		log.Printf("Error fetching collections: %s", err)
	}
	err = c.fetchRemoteFiles(ctx)
	if err != nil {
		log.Printf("Error fetching files: %s", err)
	}
	return nil
}

func (c *ClICtrl) buildRequestContext(ctx context.Context, account model.Account) context.Context {
	ctx = context.WithValue(ctx, "app", string(account.App))
	ctx = context.WithValue(ctx, "account_id", account.AccountKey())
	ctx = context.WithValue(ctx, "user_id", account.UserID)
	return ctx
}

func createDataBuckets(db *bolt.DB, account model.Account) error {
	return db.Update(func(tx *bolt.Tx) error {
		dataBucket, err := tx.CreateBucketIfNotExists([]byte(account.AccountKey()))
		if err != nil {
			return fmt.Errorf("create bucket: %s", err)
		}
		for _, subBucket := range []model.PhotosStore{model.KVConfig, model.RemoteAlbums, model.RemoteFiles} {
			_, err := dataBucket.CreateBucketIfNotExists([]byte(subBucket))
			if err != nil {
				return err
			}
		}
		return nil
	})
}
