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

type EnablePassKeyRecovery struct {
	UserID      int64   `json:"userID" binding:"required"`
	ResetKey    string  `json:"resetKey" binding:"required"`
	EncResetKey EncData `json:"encResetKey" binding:"required"`
}

type AccountRecoveryStatus struct {
	// AllowAdminReset is a boolean that determines if the admin can reset the user's MFA.
	// If true, in the event that the user loses their MFA device, the admin can reset the user's MFA.
	AllowAdminReset       bool `json:"allowAdminReset" binding:"required"`
	IsPassKeyResetEnabled bool `json:"isPassKeyResetEnabled" binding:"required"`
}

type PasseKeyResetChallengeResponse struct {
	EncResetKey      string `json:"encResetKey" binding:"required"`
	EncResetKeyNonce string `json:"encResetKeyNonce" binding:"required"`
}

type ResetPassKey struct {
	SessionID string `json:"sessionID" binding:"required"`
	RestKey   string `json:"resetKey" binding:"required"`
}
