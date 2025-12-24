package ente

import (
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v4"
)

const publicActorTokenType = "public-actor"

// PublicActorClaim represents a JWT for signed-in users acting on public albums
// without joining them. This allows users to like/comment on public albums
// using their Ente identity without needing to redirect for each action.
type PublicActorClaim struct {
	Typ          string `json:"typ"`
	UserID       int64  `json:"uid"`
	CollectionID int64  `json:"cid"`
	jwt.RegisteredClaims
}

// NewPublicActorToken creates a token for a signed-in user to act on a specific
// public collection. The token is valid for 7 days.
func NewPublicActorToken(secret []byte, userID int64, collectionID int64) (string, int64, error) {
	issuedAt := time.Now()
	expiry := issuedAt.AddDate(0, 0, 7) // 7 days validity
	claim := PublicActorClaim{
		Typ:          publicActorTokenType,
		UserID:       userID,
		CollectionID: collectionID,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   fmt.Sprintf("%d", userID),
			Issuer:    "museum",
			IssuedAt:  jwt.NewNumericDate(issuedAt),
			ExpiresAt: jwt.NewNumericDate(expiry),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claim)
	tokenString, err := token.SignedString(secret)
	if err != nil {
		return "", 0, err
	}
	return tokenString, MicrosecondsFromTime(expiry), nil
}

// ParsePublicActorToken validates the token and returns the parsed claim.
// Returns an error if the token is invalid, expired, or malformed.
func ParsePublicActorToken(secret []byte, tokenString string) (*PublicActorClaim, error) {
	token, err := jwt.ParseWithClaims(tokenString, &PublicActorClaim{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return secret, nil
	})
	if err != nil {
		return nil, err
	}
	claim, ok := token.Claims.(*PublicActorClaim)
	if !ok || !token.Valid || claim.Typ != publicActorTokenType {
		return nil, fmt.Errorf("invalid public actor token")
	}
	if claim.UserID <= 0 || claim.CollectionID <= 0 {
		return nil, fmt.Errorf("invalid user or collection in public actor token")
	}
	return claim, nil
}
