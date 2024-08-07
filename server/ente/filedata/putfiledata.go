package filedata

import (
	"fmt"
	"github.com/ente-io/museum/ente"
)

type PutFileDataRequest struct {
	FileID           int64           `json:"fileID" binding:"required"`
	Type             ente.ObjectType `json:"type" binding:"required"`
	EncryptedData    *string         `json:"encryptedData,omitempty"`
	DecryptionHeader *string         `json:"decryptionHeader,omitempty"`
	// ObjectKey is the key of the object in the S3 bucket. This is needed while putting the object in the S3 bucket.
	ObjectKey *string `json:"objectKey,omitempty"`
	// size of the object that is being uploaded. This helps in checking the size of the object that is being uploaded.
	ObjectSize *int64 `json:"objectSize,omitempty"`
	Version    *int   `json:"version,omitempty"`
}

func (r PutFileDataRequest) Validate() error {
	switch r.Type {
	case ente.PreviewVideo:
		if r.EncryptedData == nil || r.DecryptionHeader == nil || *r.EncryptedData == "" || *r.DecryptionHeader == "" {
			// the video playlist is uploaded as part of encrypted data and decryption header
			return ente.NewBadRequestWithMessage("encryptedData and decryptionHeader are required for preview video")
		}
		if r.ObjectSize == nil || r.ObjectKey == nil {
			return ente.NewBadRequestWithMessage("size and objectKey are required for preview video")
		}
	case ente.PreviewImage:
		if r.ObjectSize == nil || r.ObjectKey == nil {
			return ente.NewBadRequestWithMessage("size and objectKey are required for preview image")
		}
	case ente.DerivedMeta:
		if r.EncryptedData == nil || r.DecryptionHeader == nil || *r.EncryptedData == "" || *r.DecryptionHeader == "" {
			return ente.NewBadRequestWithMessage("encryptedData and decryptionHeader are required for derived meta")
		}
	default:
		return ente.NewBadRequestWithMessage(fmt.Sprintf("invalid object type %s", r.Type))
	}
	return nil
}

func (r PutFileDataRequest) S3FileMetadataObjectKey(ownerID int64) string {
	if r.Type == ente.DerivedMeta {
		return derivedMetaPath(r.FileID, ownerID)
	}
	if r.Type == ente.PreviewVideo {
		return previewVideoPlaylist(r.FileID, ownerID)
	}
	panic(fmt.Sprintf("S3FileMetadata should not be written for %s type", r.Type))
}
