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

type ConfigurePassKeyRecoveryRequest struct {
	SkipSecret string `json:"resetSecret" binding:"required"`
	// The UserSecretCipher has SkipSecret encrypted with the user's recoveryKey
	// If the user sends the correct UserSecretCipher, we can be sure that the user has the recoveryKey,
	// and we can allow the user to recover their MFA.
	UserSecretCipher string `json:"userSecretCipher" binding:"required"`
	UserSecretNonce  string `json:"userSecretNonce" binding:"required"`
}

type TwoFactorRecoveryStatus struct {
	// AllowAdminReset is a boolean that determines if the admin can reset the user's MFA.
	// If true, in the event that the user loses their MFA device, the admin can reset the user's MFA.
	AllowAdminReset      bool `json:"allowAdminReset" binding:"required"`
	IsPassKeySkipEnabled bool `json:"isPassKeyResetEnabled" binding:"required"`
}

type PasseKeySkipChallengeResponse struct {
	// The PassKeyEncSecret has SkipSecret encrypted with the user's recoveryKey
	UserSecretCipher string `json:"userSecretCipher" binding:"required"`
	UserSecretNonce  string `json:"userSecretNonce" binding:"required"`
}

type SkipPassKeyRequest struct {
	SessionID  string `json:"sessionID" binding:"required"`
	SkipSecret string `json:"resetSecret" binding:"required"`
}
