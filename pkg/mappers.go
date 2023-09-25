package pkg

import (
	"cli-go/internal/api"
	enteCrypto "cli-go/internal/crypto"
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
	"encoding/json"
	"errors"
	"log"
)

func (c *ClICtrl) mapCollectionToAlbum(ctx context.Context, collection api.Collection) (*model.Album, error) {
	var album model.Album
	userID := ctx.Value("user_id").(int64)
	album.OwnerID = collection.Owner.ID
	album.ID = collection.ID
	album.IsShared = collection.Owner.ID != userID
	album.LastUpdatedAt = collection.UpdationTime
	album.IsDeleted = collection.IsDeleted
	collectionKey, err := c.KeyHolder.GetCollectionKey(ctx, collection)
	if err != nil {
		return nil, err
	}
	album.AlbumKey = *model.MakeEncString(collectionKey, c.CliKey)
	var name string
	if collection.EncryptedName != "" {
		decrName, err := enteCrypto.SecretBoxOpenBase64(collection.EncryptedName, collection.NameDecryptionNonce, collectionKey)
		if err != nil {
			log.Fatalf("failed to decrypt collection name: %v", err)
		}
		name = string(decrName)
	} else {
		// Early beta users (friends & family) might have collections without encrypted names
		name = collection.Name
	}
	album.AlbumName = name
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

func (c *ClICtrl) mapApiFileToPhotoFile(ctx context.Context, album model.Album, file api.File) (*model.PhotoFile, error) {
	if file.IsDeleted {
		return nil, errors.New("file is deleted")
	}
	albumKey := album.AlbumKey.MustDecrypt(c.CliKey)
	fileKey, err := enteCrypto.SecretBoxOpen(
		encoding.DecodeBase64(file.EncryptedKey),
		encoding.DecodeBase64(file.KeyDecryptionNonce),
		albumKey)
	if err != nil {
		return nil, err
	}
	var photoFile model.PhotoFile
	photoFile.ID = file.ID
	photoFile.Key = *model.MakeEncString(fileKey, c.CliKey)
	photoFile.FileNonce = file.File.DecryptionHeader
	photoFile.ThumbnailNonce = file.Thumbnail.DecryptionHeader
	photoFile.OwnerID = file.OwnerID
	if file.Info != nil {
		photoFile.PhotoInfo = model.PhotoInfo{
			FileSize:      file.Info.FileSize,
			ThumbnailSize: file.Info.ThumbnailSize,
		}
	}
	if file.Metadata.DecryptionHeader != "" {
		_, encodedJsonBytes, err := enteCrypto.DecryptChaChaBase64(file.Metadata.EncryptedData, fileKey, file.Metadata.DecryptionHeader)
		if err != nil {
			return nil, err
		}
		err = json.Unmarshal(encodedJsonBytes, &photoFile.PrivateMetadata)
		if err != nil {
			return nil, err
		}
	}
	if file.MagicMetadata != nil {
		_, encodedJsonBytes, err := enteCrypto.DecryptChaChaBase64(file.MagicMetadata.Data, fileKey, file.MagicMetadata.Header)
		if err != nil {
			return nil, err
		}
		err = json.Unmarshal(encodedJsonBytes, &photoFile.PublicMetadata)
		if err != nil {
			return nil, err
		}
	}
	return &photoFile, nil

}
