package authenticator

import "github.com/google/uuid"

type Key struct {
	UserID       int64  `json:"userID" binding:"required"`
	EncryptedKey string `json:"encryptedKey" binding:"required"`
	Header       string `json:"header" binding:"required"`
	CreatedAt    int64  `json:"createdAt" binding:"required"`
}

// Entity represents a single TOTP Entity
type Entity struct {
	ID            uuid.UUID `json:"id" binding:"required"`
	UserID        int64     `json:"userID" binding:"required"`
	EncryptedData *string   `json:"encryptedData" binding:"required"`
	Header        *string   `json:"header" binding:"required"`
	IsDeleted     bool      `json:"isDeleted" binding:"required"`
	CreatedAt     int64     `json:"createdAt" binding:"required"`
	UpdatedAt     int64     `json:"updatedAt" binding:"required"`
}

// CreateKeyRequest represents a request to create totp encryption key for user
type CreateKeyRequest struct {
	EncryptedKey string `json:"encryptedKey" binding:"required"`
	Header       string `json:"header" binding:"required"`
}

// CreateEntityRequest...
type CreateEntityRequest struct {
	EncryptedData string `json:"encryptedData" binding:"required"`
	Header        string `json:"header" binding:"required"`
}

// UpdateEntityRequest...
type UpdateEntityRequest struct {
	ID            uuid.UUID `json:"id" binding:"required"`
	EncryptedData string    `json:"encryptedData" binding:"required"`
	Header        string    `json:"header" binding:"required"`
}

// GetEntityDiffRequest...
type GetEntityDiffRequest struct {
	// SinceTime *int64. Pointer allows us to pass 0 value otherwise binding fails for zero Value.
	SinceTime *int64 `form:"sinceTime" binding:"required"`
	Limit     int16  `form:"limit" binding:"required"`
}
