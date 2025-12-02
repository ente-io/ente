package public

import (
	"database/sql"
	"errors"
	"strings"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/social"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

func resolvePublicActor(c *gin.Context, userAuthRepo *repo.UserAuthRepository, jwtSecret []byte, bodyAnonID *string, bodyAnonToken string, requireIdentity bool) (social.Actor, error) {
	if token := auth.GetToken(c); token != "" {
		app := auth.GetApp(c)
		userID, expired, err := userAuthRepo.GetUserIDWithToken(token, app)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				return social.Actor{}, ente.ErrAuthenticationRequired
			}
			return social.Actor{}, stacktrace.Propagate(err, "")
		}
		if expired {
			return social.Actor{}, ente.ErrAuthenticationRequired
		}
		return social.Actor{UserID: &userID}, nil
	}

	anonID, anonToken := extractAnonIdentity(c, bodyAnonID, bodyAnonToken)
	if anonID == nil || anonToken == "" {
		if requireIdentity {
			return social.Actor{}, ente.ErrAuthenticationRequired
		}
		return social.Actor{}, nil
	}
	claim, err := ente.ParseAnonymousIdentityToken(jwtSecret, anonToken)
	if err != nil {
		return social.Actor{}, stacktrace.Propagate(err, "")
	}
	if claim.Subject != *anonID {
		return social.Actor{}, ente.ErrBadRequest
	}
	actor := social.Actor{AnonUserID: anonID}
	if err := actor.ValidateAnon(); err != nil {
		return social.Actor{}, err
	}
	return actor, nil
}

func extractAnonIdentity(c *gin.Context, bodyAnonID *string, bodyAnonToken string) (*string, string) {
	headerAnonID := strings.TrimSpace(c.GetHeader("X-Anon-User-ID"))
	var anonID *string
	if headerAnonID != "" {
		copyID := headerAnonID
		anonID = &copyID
	}
	headerToken := parseBearerToken(c.GetHeader("Authorization"))
	token := headerToken
	if token == "" {
		token = strings.TrimSpace(bodyAnonToken)
	}
	if anonID == nil && bodyAnonID != nil && *bodyAnonID != "" {
		anonID = bodyAnonID
	}
	return anonID, token
}

func parseBearerToken(header string) string {
	if header == "" {
		return ""
	}
	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 {
		return ""
	}
	if strings.EqualFold(parts[0], "Bearer") {
		return strings.TrimSpace(parts[1])
	}
	return ""
}
