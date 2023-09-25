package model

type RemoteFile struct {
	ID              int64                  `json:"id"`
	OwnerID         int64                  `json:"ownerID"`
	Key             EncString              `json:"key"`
	LastUpdateTime  int64                  `json:"lastUpdateTime"`
	FileNonce       string                 `json:"fileNonce"`
	ThumbnailNonce  string                 `json:"thumbnailNonce"`
	Metadata        map[string]interface{} `json:"metadata"`
	PrivateMetadata map[string]interface{} `json:"privateMetadata"`
	PublicMetadata  map[string]interface{} `json:"publicMetadata"`
	Info            Info                   `json:"info"`
}

type Info struct {
	FileSize      int64 `json:"fileSize,omitempty"`
	ThumbnailSize int64 `json:"thumbSize,omitempty"`
}

type RemoteAlbum struct {
	ID            int64                  `json:"id"`
	OwnerID       int64                  `json:"ownerID"`
	IsShared      bool                   `json:"isShared"`
	IsDeleted     bool                   `json:"isDeleted"`
	AlbumName     string                 `json:"albumName"`
	AlbumKey      EncString              `json:"albumKey"`
	PublicMeta    map[string]interface{} `json:"publicMeta"`
	PrivateMeta   map[string]interface{} `json:"privateMeta"`
	SharedMeta    map[string]interface{} `json:"sharedMeta"`
	LastUpdatedAt int64                  `json:"lastUpdatedAt"`
}
