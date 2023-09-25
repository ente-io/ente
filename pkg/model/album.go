package model

type Album struct {
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
