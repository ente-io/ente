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

func (r PutFileDataRequest) isEncDataPresent() bool {
	return r.EncryptedData != nil && r.DecryptionHeader != nil && *r.EncryptedData != "" && *r.DecryptionHeader != ""
}

func (r PutFileDataRequest) isObjectDataPresent() bool {
	return r.ObjectKey != nil && *r.ObjectKey != "" && r.ObjectSize != nil && *r.ObjectSize > 0
}

func (r PutFileDataRequest) Validate() error {
	switch r.Type {
	case ente.PreviewVideo:
		if !r.isEncDataPresent() || !r.isObjectDataPresent() {
			return ente.NewBadRequestWithMessage("object and metadata are required")
		}
	case ente.PreviewImage:
		if !r.isObjectDataPresent() || r.isEncDataPresent() {
			return ente.NewBadRequestWithMessage("object (only) data is required for preview image")
		}
	case ente.MlData:
		if !r.isEncDataPresent() || r.isObjectDataPresent() {
			return ente.NewBadRequestWithMessage("encryptedData and decryptionHeader (only) are required for derived meta")
		}
	default:
		return ente.NewBadRequestWithMessage(fmt.Sprintf("invalid object type %s", r.Type))
	}
	return nil
}

func (r PutFileDataRequest) S3FileMetadataObjectKey(ownerID int64) string {
	if r.Type == ente.MlData {
		return derivedMetaPath(r.FileID, ownerID)
	}
	if r.Type == ente.PreviewVideo {
		return previewVideoPlaylist(r.FileID, ownerID)
	}
	panic(fmt.Sprintf("S3FileMetadata should not be written for %s type", r.Type))
}

func (r PutFileDataRequest) S3FileObjectKey(ownerID int64) string {
	if r.Type == ente.PreviewVideo {
		return previewVideoPath(r.FileID, ownerID)
	}
	if r.Type == ente.PreviewImage {
		return previewImagePath(r.FileID, ownerID)
	}
	panic(fmt.Sprintf("S3FileObjectKey should not be written for %s type", r.Type))
}
