package public

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	gonanoid "github.com/matoous/go-nanoid/v2"
)

// AnonIdentityController issues anonymous identities for public commenters.
type AnonIdentityController struct {
	JwtSecret []byte
}

// AnonIdentityResponse is returned when minting anon identities.
type AnonIdentityResponse struct {
	AnonUserID string `json:"anonUserID"`
	Token      string `json:"token"`
	ExpiresAt  int64  `json:"expiresAt"`
}

func (c *AnonIdentityController) Create(ctx *gin.Context) (AnonIdentityResponse, error) {
	anonID, err := gonanoid.New()
	if err != nil {
		return AnonIdentityResponse{}, stacktrace.Propagate(err, "")
	}
	token, expiresAt, err := ente.NewAnonymousIdentityToken(c.JwtSecret, anonID)
	if err != nil {
		return AnonIdentityResponse{}, stacktrace.Propagate(err, "")
	}
	return AnonIdentityResponse{
		AnonUserID: anonID,
		Token:      token,
		ExpiresAt:  expiresAt,
	}, nil
}
