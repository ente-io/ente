package middleware

import (
	"database/sql"
	"errors"
	"fmt"
	"github.com/sirupsen/logrus"
	"net/http"
	"strconv"

	"github.com/ente-io/museum/ente/jwt"
	"github.com/ente-io/museum/pkg/utils/network"

	"github.com/ente-io/museum/pkg/controller/user"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/gin-gonic/gin"
	"github.com/patrickmn/go-cache"
	"github.com/spf13/viper"
)

// AuthMiddleware intercepts and authenticates incoming requests
type AuthMiddleware struct {
	UserAuthRepo   *repo.UserAuthRepository
	Cache          *cache.Cache
	UserController *user.UserController
}

// TokenAuthMiddleware returns a middle ware that extracts the `X-AuthToken`
// within the header of a request and uses it to authenticate and insert the
// authenticated user to the request's `X-Auth-User-ID` field.
// If isJWT is true we use JWT token validation
func (m *AuthMiddleware) TokenAuthMiddleware(jwtClaimScope *jwt.ClaimScope) gin.HandlerFunc {
	return func(c *gin.Context) {
		token := auth.GetToken(c)
		if token == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing token"})
			return
		}
		app := auth.GetApp(c)
		cacheKey := fmt.Sprintf("%s:%s", app, token)
		isJWT := false
		if jwtClaimScope != nil {
			isJWT = true
			cacheKey = fmt.Sprintf("%s:%s:%s", app, token, *jwtClaimScope)
		}
		userID, found := m.Cache.Get(cacheKey)
		var err error
		if !found {
			if isJWT {
				userID, err = m.UserController.ValidateJWTToken(token, *jwtClaimScope)
			} else {
				userID, err = m.UserAuthRepo.GetUserIDWithToken(token, app)
				if err != nil && !errors.Is(err, sql.ErrNoRows) {
					logrus.Errorf("Failed to validate token: %s", err)
					c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "failed to validate token"})
					return
				}
			}
			if err != nil {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
				return
			}
			if !isJWT {
				ip := network.GetClientIP(c)
				userAgent := c.Request.UserAgent()
				// skip updating last used for requests routed via CF worker
				if !network.IsCFWorkerIP(ip) {
					go func() {
						_ = m.UserAuthRepo.UpdateLastUsedAt(userID.(int64), token, ip, userAgent)
					}()
				}
			}
			m.Cache.Set(cacheKey, userID, cache.DefaultExpiration)
		}
		c.Request.Header.Set("X-Auth-User-ID", strconv.FormatInt(userID.(int64), 10))
		c.Next()
	}
}

// AdminAuthMiddleware returns a middle ware that extracts the `userID` added by the TokenAuthMiddleware
// within the header of a request and uses it to check admin status
// NOTE: Should be added after TokenAuthMiddleware middleware
func (m *AuthMiddleware) AdminAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		userID := auth.GetUserID(c.Request.Header)
		admins := viper.GetIntSlice("internal.admins")
		for _, admin := range admins {
			if int64(admin) == userID {
				c.Next()
				return
			}
		}
		// The config allows alternatively specifying a singular admin ID to
		// workaround Viper issues in passing env vars for an int slice.
		admin := viper.GetInt("internal.admin")
		if len(admins) == 0 && admin != 0 {
			if int64(admin) == userID {
				c.Next()
				return
			}
		}
		// if no admins are set, then check if the user is first user in the system
		if len(admins) == 0 && admin == 0 {
			id, err := m.UserAuthRepo.GetMinUserID()
			if err != nil && id == userID {
				c.Next()
				return
			}
		}
		c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "insufficient permissions"})
	}
}
