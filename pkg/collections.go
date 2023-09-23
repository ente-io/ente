package pkg

import (
	"cli-go/internal/api"
	enteCrypto "cli-go/internal/crypto"
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
	"fmt"
	"log"
)

func (c *ClICtrl) syncRemoteCollections(ctx context.Context, info model.Account) error {
	collections, err := c.Client.GetCollections(ctx, 0)
	if err != nil {
		return fmt.Errorf("failed to get collections: %s", err)
	}
	for _, collection := range collections {
		collectionKey, err := c.getCollectionKey(ctx, collection)
		if err != nil {
			return err
		}
		name, nameErr := enteCrypto.SecretBoxOpenBase64(collection.EncryptedName, collection.NameDecryptionNonce, collectionKey)
		if nameErr != nil {
			log.Fatalf("failed to decrypt collection name: %v", nameErr)
		}
		if collection.Owner.ID != info.UserID {
			fmt.Printf("Shared Album %s\n", string(name))
			continue
		} else {
			fmt.Printf("Owned Name %s\n", string(name))
		}
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
		collKey, err := enteCrypto.SealedBoxOpen(encoding.DecodeBase64(collection.EncryptedKey),
			accSecretInfo.PublicKey, accSecretInfo.SecretKey)
		if err != nil {
			log.Fatalf("failed to decrypt collection key %s", err)
		}
		return collKey, nil
	}
}
