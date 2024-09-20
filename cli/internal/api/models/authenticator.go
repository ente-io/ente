package models

type AuthKey struct {
	UserID       int64  `json:"userID" binding:"required"`
	EncryptedKey string `json:"encryptedKey" binding:"required"`
	Header       string `json:"header" binding:"required"`
}

type AuthEntity struct {
	ID            string  `json:"id" binding:"required"`
	EncryptedData *string `json:"encryptedData"`
	Header        *string `json:"header"`
	IsDeleted     bool    `json:"isDeleted" binding:"required"`
	CreatedAt     int64   `json:"createdAt" binding:"required"`
	UpdatedAt     int64   `json:"updatedAt" binding:"required"`
}
