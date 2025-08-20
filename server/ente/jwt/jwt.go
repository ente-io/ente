package jwt

import (
	"errors"
	"github.com/ente-io/museum/pkg/utils/time"
)

type ClaimScope string

const (
	PAYMENT        ClaimScope = "PAYMENT"
	FAMILIES       ClaimScope = "FAMILIES"
	ACCOUNTS       ClaimScope = "ACCOUNTS"
	DELETE_ACCOUNT ClaimScope = "DELETE_ACCOUNT"
	RestoreAccount ClaimScope = "RestoreAccount"
)

func (c ClaimScope) Ptr() *ClaimScope {
	return &c
}

type WebCommonJWTClaim struct {
	UserID     int64       `json:"userID,omitempty"`
	ExpiryTime int64       `json:"expiryTime,omitempty"`
	Email      string      `json:"email,omitempty"`
	ClaimScope *ClaimScope `json:"claimScope,omitempty"`
}

func (w *WebCommonJWTClaim) GetScope() ClaimScope {
	if w.ClaimScope == nil {
		return PAYMENT
	}
	return *w.ClaimScope
}

func (w WebCommonJWTClaim) Valid() error {
	if w.ExpiryTime < time.Microseconds() {
		return errors.New("token expired")
	}
	return nil
}

// LinkPasswordClaim refer to token granted post link password verification
type LinkPasswordClaim struct {
	PassHash   string `json:"passKey"`
	ExpiryTime int64  `json:"expiryTime"`
}

func (c LinkPasswordClaim) Valid() error {
	if c.ExpiryTime < time.Microseconds() {
		return errors.New("token expired")
	}
	return nil
}
