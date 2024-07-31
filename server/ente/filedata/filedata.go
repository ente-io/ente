package filedata

import (
	"fmt"
	"github.com/ente-io/museum/ente"
)

type PutFileDataRequest struct {
	FileID           int64           `json:"fileID" binding:"required"`
	Type             ente.ObjectType `json:"type" binding:"required"`
	EncryptedData    *string         `json:"encryptedData"`
	DecryptionHeader *string         `json:"decryptionHeader"`
	// ObjectKey is the key of the object in the S3 bucket. This is needed while putting the object in the S3 bucket.
	ObjectKey *string `json:"objectKey"`
	// size of the object that is being uploaded. This helps in checking the size of the object that is being uploaded.
	Size *int64 `json:"size" `
}

func (r PutFileDataRequest) Validate() error {
	switch r.Type {
	case ente.PreviewVideo:
		if r.EncryptedData == nil || r.DecryptionHeader == nil || *r.EncryptedData == "" || *r.DecryptionHeader == "" {
			// the video playlist is uploaded as part of encrypted data and decryption header
			return ente.NewBadRequestWithMessage("encryptedData and decryptionHeader are required for preview video")
		}
		if r.Size == nil || r.ObjectKey == nil {
			return ente.NewBadRequestWithMessage("size and objectKey are required for preview video")
		}
	case ente.PreviewImage:
		if r.Size == nil || r.ObjectKey == nil {
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

// GetFilesData should only be used for getting the preview video playlist and derived metadata.
type GetFilesData struct {
	FileIDs []int64         `form:"fileIDs" binding:"required"`
	Type    ente.ObjectType `json:"type" binding:"required"`
}

func (g *GetFilesData) Validate() error {
	if g.Type != ente.PreviewVideo && g.Type != ente.DerivedMeta {
		return ente.NewBadRequestWithMessage(fmt.Sprintf("unsupported object type %s", g.Type))
	}
	return nil
}

type Entity struct {
	FileID           int64           `json:"fileID"`
	Type             ente.ObjectType `json:"type"`
	EncryptedData    string          `json:"encryptedData"`
	DecryptionHeader string          `json:"decryptionHeader"`
}

type GetFilesDataResponse struct {
	Data                []Entity `json:"data"`
	PendingIndexFileIDs []int64  `json:"pendingIndexFileIDs"`
	ErrFileIDs          []int64  `json:"errFileIDs"`
}
