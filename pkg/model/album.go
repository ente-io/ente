package model

type Album struct {
	ID            int64     `json:"id"`
	OwnerID       int64     `json:"ownerID"`
	IsShared      bool      `json:"isShared"`
	IsDeleted     bool      `json:"isDeleted"`
	AlbumName     string    `json:"albumName"`
	AlbumKey      EncString `json:"albumKey"`
	PublicMeta    *string   `json:"publicMeta"`
	PrivateMeta   *string   `json:"privateMeta"`
	SharedMeta    *string   `json:"sharedMeta"`
	LastUpdatedAt int64     `json:"lastUpdatedAt"`
}
