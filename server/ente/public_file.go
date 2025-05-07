package ente

// CreateFileUrl represents an encrypted file in the system
type CreateFileUrl struct {
	FileID int64 `json:"fileID" binding:"required"`
}

// UpdateFileResponse represents a response to the UpdateFileRequest
type UpdateFileUrl struct {
	LinkID          string        `json:"linkID" binding:"required"`
	FileID          int64         `json:"fileID" binding:"required"`
	ValidTill       *int64        `json:"validTill"`
	DeviceLimit     *int          `json:"deviceLimit"`
	PasswordInfo    *PassWordInfo `json:"passHash"`
	EnableDownload  *bool         `json:"enableDownload"`
	DisablePassword *bool         `json:"disablePassword"`
}

type PassWordInfo struct {
	PassHash string `json:"passHash" binding:"required"`
	Nonce    string `json:"nonce" binding:"required"`
	MemLimit int64  `json:"memLimit" binding:"required"`
	OpsLimit int64  `json:"opsLimit" binding:"required"`
}

type PublicFileUrlRow struct {
	LinkID         string
	OwnerID        int64
	FileID         int64
	Token          string
	DeviceLimit    int
	ValidTill      int64
	IsDisabled     bool
	PasswordInfo   *PassWordInfo
	EnableDownload bool
	CreatedAt      int64
}

type FileUrl struct {
	LinkID          string `json:"linkID" binding:"required"`
	OwnerID         int64  `json:"ownerID" binding:"required"`
	FileID          int64  `json:"fileID" binding:"required"`
	ValidTill       int64  `json:"validTill"`
	DeviceLimit     int    `json:"deviceLimit"`
	PasswordEnabled bool   `json:"passwordEnabled"`
	EnableDownload  bool   `json:"enableDownload"`
	CreatedAt       int64  `json:"createdAt"`
}
