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

type ConfigurePassKeySkipRequest struct {
	PassKeySkipSecret    string  `json:"passKeySkipSecret" binding:"required"`
	EncPassKeySkipSecret EncData `json:"encPassKeySkipSecret" binding:"required"`
}

type TwoFactorRecoveryStatus struct {
	// AllowAdminReset is a boolean that determines if the admin can reset the user's MFA.
	// If true, in the event that the user loses their MFA device, the admin can reset the user's MFA.
	AllowAdminReset      bool `json:"allowAdminReset" binding:"required"`
	IsPassKeySkipEnabled bool `json:"isPassKeySkipEnabled" binding:"required"`
}

type PasseKeySkipChallengeResponse struct {
	EncData
}

type SkipPassKeyRequest struct {
	SessionID         string `json:"sessionID" binding:"required"`
	PassKeySkipSecret string `json:"passKeySkipSecret" binding:"required"`
}
