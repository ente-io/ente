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
	Version          *int            `json:"version,omitempty"`
}

func (r PutFileDataRequest) isEncDataPresent() bool {
	return r.EncryptedData != nil && r.DecryptionHeader != nil && *r.EncryptedData != "" && *r.DecryptionHeader != ""
}

func (r PutFileDataRequest) Validate() error {
	switch r.Type {
	case ente.MlData:
		if !r.isEncDataPresent() {
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

	panic(fmt.Sprintf("S3FileMetadata should not be written for %s type", r.Type))
}

func (r PutFileDataRequest) S3FileObjectKey(ownerID int64) string {
	panic(fmt.Sprintf("S3FileObjectKey should not be written for %s type", r.Type))
}
