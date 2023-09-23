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
		collectionKey, err := c.KeyHolder.GetCollectionKey(ctx, collection)
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
