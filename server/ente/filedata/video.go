package filedata

import "github.com/ente-io/museum/ente"

type PutVidRequest struct {
	FileID                int64           `json:"fileID" binding:"required"`
	Type                  ente.ObjectType `json:"type" binding:"required"`
	ObjectID              string          `json:"objectID" binding:"required"`
	ObjectSize            int64           `json:"objectSize" binding:"required"`
	PlayListEncryptedData string          `json:"playListEncryptedData,omitempty"`
	PlayListDecryptionKey string          `json:"playListDecryptionHeader,omitempty"`
}

func (r PutVidRequest) Validate() error {
	switch r.Type {
	case ente.PreviewVideo:
		if r.PlayListEncryptedData == "" || r.PlayListDecryptionKey == "" {
			return ente.NewBadRequestWithMessage("playListEncryptedData and playListDecryptionHeader are required for preview video")
		}
		if r.ObjectSize <= 0 {
			return ente.NewBadRequestWithMessage("objectSize should be greater than 0")
		}
	default:
		return ente.NewBadRequestWithMessage("invalid object type")
	}
	return nil
}
