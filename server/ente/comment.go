package ente

import "encoding/json"

// Comment represents an encrypted comment or reply stored in the database.
type Comment struct {
	ID              string          `json:"id"`
	CollectionID    int64           `json:"collectionID"`
	FileID          *int64          `json:"fileID,omitempty"`
	ParentCommentID *string         `json:"parentCommentID,omitempty"`
	UserID          int64           `json:"userID"`
	AnonUserID      *string         `json:"anonUserID,omitempty"`
	Payload         json.RawMessage `json:"payload,omitempty"`
	IsDeleted       bool            `json:"isDeleted"`
	CreatedAt       int64           `json:"createdAt"`
	UpdatedAt       int64           `json:"updatedAt"`
}
