package pkg

import (
	"cli-go/internal/api"
	enteCrypto "cli-go/internal/crypto"
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
	"encoding/base64"
	"fmt"
	bolt "go.etcd.io/bbolt"
	"log"
)

func (c *ClICtrl) SyncAccount(account model.Account) error {
	log.SetPrefix(fmt.Sprintf("[%s] ", account.Email))
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
	return c.syncRemoteCollections(ctx, account)
}

func (c *ClICtrl) buildRequestContext(ctx context.Context, account model.Account) context.Context {
	ctx = context.WithValue(ctx, "app", string(account.App))
	ctx = context.WithValue(ctx, "account_id", account.AccountKey())
	ctx = context.WithValue(ctx, "user_id", account.UserID)
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
		return fmt.Errorf("failed to get collections: %s", err)
	}
	for _, collection := range collections {
		if collection.Owner.ID != info.UserID {
			fmt.Printf("Skipping collection %d\n", collection.ID)
			continue
		}
		collectionKey, err := c.getCollectionKey(ctx, collection)
		if err != nil {
			return err
		}
		name, nameErr := enteCrypto.SecretBoxOpenBase64(collection.EncryptedName, collection.NameDecryptionNonce, collectionKey)
		if nameErr != nil {
			log.Fatalf("failed to decrypt collection name: %v", nameErr)
		}
		fmt.Printf("Collection Name %s\n", string(name))
	}
	return nil
}

func (c *ClICtrl) getCollectionKey(ctx context.Context, collection api.Collection) ([]byte, error) {
	accSecretInfo := c.KeyHolder.GetAccountSecretInfo(ctx)
	userID := ctx.Value("user_id").(int64)
	if collection.Owner.ID == userID {
		collKey, err := enteCrypto.SecretBoxOpen(
			encoding.DecodeBase64(collection.EncryptedKey),
			encoding.DecodeBase64(collection.KeyDecryptionNonce),
			accSecretInfo.MasterKey)
		if err != nil {
			log.Fatalf("failed to decrypt collection key %s", err)
		}
		return collKey, nil
	} else {
		panic("not implemented")
	}
}
