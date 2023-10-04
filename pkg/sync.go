package pkg

import (
	"cli-go/pkg/model"
	"context"
	"encoding/base64"
	"fmt"
	bolt "go.etcd.io/bbolt"
	"log"
)

func (c *ClICtrl) StartSync() error {
	accounts, err := c.GetAccounts(context.Background())
	if err != nil {
		return err
	}
	if len(accounts) == 0 {
		fmt.Printf("No accounts to sync\n")
		return nil
	}
	for _, account := range accounts {
		log.SetPrefix(fmt.Sprintf("[%s-%s] ", account.App, account.Email))
		log.Println("start sync")
		err = c.SyncAccount(account)
		if err != nil {
			fmt.Printf("Error syncing account %s: %s\n", account.Email, err)
			return err
		} else {
			log.Println("sync done")
		}

	}
	return nil
}

func (c *ClICtrl) SyncAccount(account model.Account) error {
	secretInfo, err := c.KeyHolder.LoadSecrets(account)
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
	downloadErr := c.initiateDownload(ctx)
	if downloadErr != nil {
		log.Printf("Error downloading files: %s", downloadErr)
		return downloadErr
	}
	return nil
}

func (c *ClICtrl) buildRequestContext(ctx context.Context, account model.Account) context.Context {
	ctx = context.WithValue(ctx, "app", string(account.App))
	ctx = context.WithValue(ctx, "account_key", account.AccountKey())
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
