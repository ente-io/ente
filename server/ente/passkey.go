package ente

import "github.com/google/uuid"

// Passkey is our way of keeping track of user credentials and storing useful info for users.
type Passkey struct {
	ID           uuid.UUID `json:"id"`
	UserID       int64     `json:"userID"`
	FriendlyName string    `json:"friendlyName"`

	CreatedAt int64 `json:"createdAt"`
}

var MaxPasskeys = 10
