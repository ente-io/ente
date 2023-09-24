package pkg

import (
	"cli-go/internal/api"
	enteCrypto "cli-go/internal/crypto"
	"cli-go/pkg/model"
	"context"
	"log"
)

func (c *ClICtrl) mapCollectionToAlbum(ctx context.Context, collection api.Collection) (*model.Album, error) {
	var album model.Album
	userID := ctx.Value("user_id").(int64)
	collectionKey, err := c.KeyHolder.GetCollectionKey(ctx, collection)
	album.OwnerID = collection.Owner.ID
	album.ID = collection.ID
	album.IsShared = collection.Owner.ID != userID
	album.AlbumKey = *model.MakeEncString(collectionKey, c.CliKey)
	album.LastUpdatedAt = collection.UpdationTime
	album.IsDeleted = collection.IsDeleted
	if err != nil {
		return nil, err
	}
	name, nameErr := enteCrypto.SecretBoxOpenBase64(collection.EncryptedName, collection.NameDecryptionNonce, collectionKey)
	if nameErr != nil {
		log.Fatalf("failed to decrypt collection name: %v", nameErr)
	}
	album.AlbumName = string(name)

	if collection.MagicMetadata != nil {
		_, encodedJsonBytes, err := enteCrypto.DecryptChaChaBase64(collection.MagicMetadata.Data, collectionKey, collection.MagicMetadata.Header)
		if err != nil {
			return nil, err
		}
		var val = string(encodedJsonBytes)
		album.PrivateMeta = &val
	}
	if collection.PublicMagicMetadata != nil {
		_, encodedJsonBytes, err := enteCrypto.DecryptChaChaBase64(collection.PublicMagicMetadata.Data, collectionKey, collection.PublicMagicMetadata.Header)
		if err != nil {
			return nil, err
		}
		var val = string(encodedJsonBytes)
		album.PublicMeta = &val
	}
	if album.IsShared && collection.SharedMagicMetadata != nil {
		_, encodedJsonBytes, err := enteCrypto.DecryptChaChaBase64(collection.SharedMagicMetadata.Data, collectionKey, collection.SharedMagicMetadata.Header)
		if err != nil {
			return nil, err
		}
		var val = string(encodedJsonBytes)
		album.SharedMeta = &val
	}
	return &album, nil
}
