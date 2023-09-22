package pkg

import (
	"cli-go/pkg/model"
	"cli-go/utils"
	"context"
	"encoding/base64"
	"fmt"
	bolt "go.etcd.io/bbolt"
	"log"
)

func (c *ClICtrl) SyncAccount(account model.Account) error {
	log.SetPrefix(fmt.Sprintf("[%s] ", account.Email))
	cliSecret := GetOrCreateClISecret()
	err := createDataBuckets(c.DB, account)
	if err != nil {
		return err
	}
	token := account.Token.MustDecrypt(cliSecret)
	urlEncodedToken := base64.URLEncoding.EncodeToString(utils.Base64DecodeString(token))
	c.Client.AddToken(account.AccountKey(), urlEncodedToken)
	ctx := c.GetRequestContext(context.Background(), account)
	return c.syncRemoteCollections(ctx, account)
}

func (c *ClICtrl) GetRequestContext(ctx context.Context, account model.Account) context.Context {
	ctx = context.WithValue(ctx, "app", string(account.App))
	ctx = context.WithValue(ctx, "account_id", account.AccountKey())
	return ctx
}

var dataCategories = []string{"remote-collections", "local-collections", "remote-files", "local-files", "remote-collection-removed", "remote-files-removed"}

func createDataBuckets(db *bolt.DB, account model.Account) error {
	return db.Update(func(tx *bolt.Tx) error {
		dataBucket, err := tx.CreateBucketIfNotExists([]byte(account.DataBucket()))
		if err != nil {
			return fmt.Errorf("create bucket: %s", err)
		}
		for _, category := range dataCategories {
			_, err := dataBucket.CreateBucketIfNotExists([]byte(fmt.Sprintf(category)))
			if err != nil {
				return err
			}
		}
		return nil
	})
}

func (c *ClICtrl) syncRemoteCollections(ctx context.Context, info model.Account) error {
	collections, err := c.Client.GetCollections(ctx, 0)
	if err != nil {
		log.Printf("failed to get collections: %s\n", err)
		return err
	}
	for _, collection := range collections {
		fmt.Printf("Collection %d\n", collection.ID)
	}
	return nil
}
