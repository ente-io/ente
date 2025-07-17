package ente

// CreateFileUrl represents an encrypted file in the system
type CreateFileUrl struct {
	FileID int64 `json:"fileID" binding:"required"`
}

// UpdateFileUrl ..
type UpdateFileUrl struct {
	LinkID          string `json:"linkID" binding:"required"`
	FileID          int64  `json:"fileID" binding:"required"`
	ValidTill       *int64 `json:"validTill"`
	DeviceLimit     *int   `json:"deviceLimit"`
	PassHash        *string
	Nonce           *string
	MemLimit        *int64
	OpsLimit        *int64
	EnableDownload  *bool `json:"enableDownload"`
	DisablePassword *bool `json:"disablePassword"`
}

type FileLinkRow struct {
	LinkID         string
	OwnerID        int64
	FileID         int64
	Token          string
	DeviceLimit    int
	ValidTill      int64
	IsDisabled     bool
	PassHash       *string
	Nonce          *string
	MemLimit       *int64
	OpsLimit       *int64
	EnableDownload bool
	CreatedAt      int64
	UpdatedAt      int64
}
type FileUrl struct {
	LinkID          string `json:"linkID" binding:"required"`
	URL             string `json:"url" binding:"required"`
	OwnerID         int64  `json:"ownerID" binding:"required"`
	FileID          int64  `json:"fileID" binding:"required"`
	ValidTill       int64  `json:"validTill"`
	DeviceLimit     int    `json:"deviceLimit"`
	PasswordEnabled bool   `json:"passwordEnabled"`
	// Nonce contains the nonce value for the password if the link is password protected.
	Nonce          *string `json:"nonce,omitempty"`
	MemLimit       *int64  `json:"memLimit,omitempty"`
	OpsLimit       *int64  `json:"opsLimit,omitempty"`
	EnableDownload bool    `json:"enableDownload"`
	CreatedAt      int64   `json:"createdAt"`
}

type PublicFileAccessContext struct {
	ID        string
	IP        string
	UserAgent string
	FileID    int64
}
