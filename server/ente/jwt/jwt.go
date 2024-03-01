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
)

func (c ClaimScope) Ptr() *ClaimScope {
	return &c
}

type WebCommonJWTClaim struct {
	UserID     int64       `json:"userID"`
	ExpiryTime int64       `json:"expiryTime"`
	ClaimScope *ClaimScope `json:"claimScope"`
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

// PublicAlbumPasswordClaim refer to token granted post public album password verification
type PublicAlbumPasswordClaim struct {
	PassHash   string `json:"passKey"`
	ExpiryTime int64  `json:"expiryTime"`
}

func (c PublicAlbumPasswordClaim) Valid() error {
	if c.ExpiryTime < time.Microseconds() {
		return errors.New("token expired")
	}
	return nil
}
