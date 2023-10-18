package pkg

import (
	"cli-go/internal"
	"cli-go/pkg/model"
	"context"
	"encoding/base64"
	"fmt"
	"log"

	bolt "go.etcd.io/bbolt"
)

func (c *ClICtrl) Export() error {
	accounts, err := c.GetAccounts(context.Background())
	if err != nil {
		return err
	}
	if len(accounts) == 0 {
		fmt.Printf("No accounts to sync\n Add account using `account add` cmd\n")
		return nil
	}
	for _, account := range accounts {
		log.SetPrefix(fmt.Sprintf("[%s-%s] ", account.App, account.Email))
		if account.ExportDir == "" {
			log.Printf("Skip account %s: no export directory configured", account.Email)
			continue
		}
		_, err = internal.ValidateDirForWrite(account.ExportDir)
		if err != nil {
			log.Printf("Skip export, error: %v while validing exportDir %s\n", err, account.ExportDir)
			continue
		}
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
	err = c.createLocalFolderForRemoteAlbums(ctx, account)
	if err != nil {
		log.Printf("Error creating local folders: %s", err)
		return err
	}
	err = c.syncFiles(ctx, account)
	if err != nil {
		log.Printf("Error syncing files: %s", err)
		return err
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
		for _, subBucket := range []model.PhotosStore{model.KVConfig, model.RemoteAlbums, model.RemoteFiles, model.RemoteAlbumEntries} {
			_, err := dataBucket.CreateBucketIfNotExists([]byte(subBucket))
			if err != nil {
				return err
			}
		}
		return nil
	})
}
