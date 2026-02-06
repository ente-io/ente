package ente

// MemoryShareType represents the type of memory share
type MemoryShareType string

const (
	// MemoryShareTypeShare is a user-curated memory share with selected files
	MemoryShareTypeShare MemoryShareType = "share"
	// MemoryShareTypeLane is an auto-generated memory lane
	MemoryShareTypeLane MemoryShareType = "lane"
)

// MemoryShare represents a shared memory with its encrypted metadata
type MemoryShare struct {
	ID                 int64           `json:"id"`
	UserID             int64           `json:"-"`
	Type               MemoryShareType `json:"type"`
	MetadataCipher     string          `json:"metadataCipher,omitempty"`
	MetadataNonce      string          `json:"metadataNonce,omitempty"`
	EncryptedKey       string          `json:"encryptedKey,omitempty"`
	KeyDecryptionNonce string          `json:"keyDecryptionNonce,omitempty"`
	AccessToken        string          `json:"accessToken,omitempty"`
	IsDeleted          bool            `json:"isDeleted,omitempty"`
	CreatedAt          int64           `json:"createdAt"`
	UpdatedAt          int64           `json:"updatedAt,omitempty"`
	URL                string          `json:"url,omitempty"`
}

// MemoryShareFile represents a file within a memory share
type MemoryShareFile struct {
	ID                 int64  `json:"id"`
	MemoryShareID      int64  `json:"-"`
	FileID             int64  `json:"fileID"`
	FileOwnerID        int64  `json:"-"`
	EncryptedKey       string `json:"encryptedKey"`
	KeyDecryptionNonce string `json:"keyDecryptionNonce"`
	CreatedAt          int64  `json:"createdAt"`
}

// CreateMemoryShareRequest is the request body for creating a memory share
type CreateMemoryShareRequest struct {
	MetadataCipher     string                `json:"metadataCipher"`
	MetadataNonce      string                `json:"metadataNonce"`
	EncryptedKey       string                `json:"encryptedKey" binding:"required"`
	KeyDecryptionNonce string                `json:"keyDecryptionNonce" binding:"required"`
	Files              []MemoryShareFileItem `json:"files" binding:"required,min=1"`
}

// MemoryShareFileItem represents a file in the create request
type MemoryShareFileItem struct {
	FileID             int64  `json:"fileID" binding:"required"`
	EncryptedKey       string `json:"encryptedKey" binding:"required"`
	KeyDecryptionNonce string `json:"keyDecryptionNonce" binding:"required"`
}

// CreateMemoryShareResponse is the response for creating a memory share
type CreateMemoryShareResponse struct {
	MemoryShare MemoryShare `json:"memoryShare"`
}

// ListMemorySharesResponse is the response for listing memory shares
type ListMemorySharesResponse struct {
	MemoryShares []MemoryShare `json:"memoryShares"`
}

// PublicMemoryShareResponse is the response for public memory share access
type PublicMemoryShareResponse struct {
	MemoryShare MemoryShare `json:"memoryShare"`
}

// PublicMemoryShareFile combines file data with its re-encrypted key for public access
type PublicMemoryShareFile struct {
	File               File   `json:"file"`
	EncryptedKey       string `json:"encryptedKey"`
	KeyDecryptionNonce string `json:"keyDecryptionNonce"`
}

// PublicMemoryShareFilesResponse is the response for listing files in a public memory share
type PublicMemoryShareFilesResponse struct {
	Files []PublicMemoryShareFile `json:"files"`
}

// MemoryShareAccessContext represents the context for public memory share access
type MemoryShareAccessContext struct {
	ID          int64
	ShareID     int64
	AccessToken string
	IP          string
	UserAgent   string
}
