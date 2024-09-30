package filedata

import "github.com/ente-io/museum/ente"

type VidPreviewRequest struct {
	FileID        int64  `json:"fileID" binding:"required"`
	ObjectID      string `json:"objectID" binding:"required"`
	ObjectNonce   string `json:"objectNonce" binding:"required"`
	ObjectSize    int64  `json:"objectSize" binding:"required"`
	Playlist      string `json:"playlist" binding:"required"`
	PlayListNonce string `json:"playListNonce" binding:"required"`
	Version       *int   `json:"version"`
}

func (r VidPreviewRequest) Validate() error {
	if r.Playlist == "" || r.PlayListNonce == "" {
		return ente.NewBadRequestWithMessage("playlist and playListNonce are required for preview video")
	}
	if r.ObjectNonce == "" {
		return ente.NewBadRequestWithMessage("objectNonce is required for preview video")
	}
	return nil
}
