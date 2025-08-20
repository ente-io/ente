package middleware

import (
	"bytes"
	"context"
	"crypto/sha256"
	"fmt"
	"net/http"
	"net/url"
	"strings"

	"github.com/ente-io/museum/pkg/repo/remotestore"
	"github.com/gin-contrib/requestid"
	"github.com/spf13/viper"

	public2 "github.com/ente-io/museum/pkg/controller/public"
	"github.com/ente-io/museum/pkg/repo/public"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/controller/discord"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/array"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/network"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"github.com/patrickmn/go-cache"
	"github.com/sirupsen/logrus"
)

var passwordWhiteListedURLs = []string{"/public-collection/info", "/public-collection/report-abuse", "/public-collection/verify-password"}
var whitelistedCollectionShareIDs = []int64{111}

// CollectionLinkMiddleware intercepts and authenticates incoming requests
type CollectionLinkMiddleware struct {
	CollectionLinkRepo   *public.CollectionLinkRepo
	PublicCollectionCtrl *public2.CollectionLinkController
	CollectionRepo       *repo.CollectionRepository
	Cache                *cache.Cache
	BillingCtrl          *controller.BillingController
	DiscordController    *discord.DiscordController
	RemoteStoreRepo      *remotestore.Repository
}

// Authenticate returns a middle ware that extracts the `X-Auth-Access-Token`
// within the header of a request and uses it to validate the access token and set the
// ente.PublicAccessContext with auth.PublicAccessKey as key
func (m *CollectionLinkMiddleware) Authenticate(urlSanitizer func(_ *gin.Context) string) gin.HandlerFunc {
	return func(c *gin.Context) {
		accessToken := auth.GetAccessToken(c)
		if accessToken == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing accessToken", "context": "album_link"})
			return
		}
		clientIP := network.GetClientIP(c)
		userAgent := c.GetHeader("User-Agent")
		var publicCollectionSummary ente.PublicCollectionSummary
		var err error

		cacheKey := computeHashKeyForList([]string{accessToken, clientIP, userAgent}, ":")
		cachedValue, cacheHit := m.Cache.Get(cacheKey)
		if !cacheHit {
			publicCollectionSummary, err = m.CollectionLinkRepo.GetCollectionSummaryByToken(c, accessToken)
			if err != nil {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
				return
			}
			if publicCollectionSummary.IsDisabled {
				c.AbortWithStatusJSON(http.StatusGone, gin.H{"error": "disabled token"})
				return
			}
			// validate if user still has active paid subscription
			if err = m.validateOwnersSubscription(c, publicCollectionSummary.CollectionID); err != nil {
				logrus.WithError(err).Warn("failed to verify active paid subscription")
				c.AbortWithStatusJSON(http.StatusGone, gin.H{"error": "no active subscription"})
				return
			}

			// validate device limit
			reached, err := m.isDeviceLimitReached(c, publicCollectionSummary, clientIP, userAgent)
			if err != nil {
				logrus.WithError(err).Error("failed to check device limit")
				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"error": "something went wrong"})
				return
			}
			if reached {
				c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{"error": "reached device limit"})
				return
			}
		} else {
			publicCollectionSummary = cachedValue.(ente.PublicCollectionSummary)
		}

		if publicCollectionSummary.ValidTill > 0 && // expiry time is defined, 0 indicates no expiry
			publicCollectionSummary.ValidTill < time.Microseconds() {
			c.AbortWithStatusJSON(http.StatusGone, gin.H{"error": "expired token"})
			return
		}

		// checks password protected public collection
		if publicCollectionSummary.PassHash != nil && *publicCollectionSummary.PassHash != "" {
			reqPath := urlSanitizer(c)
			if err = m.validatePassword(c, reqPath, publicCollectionSummary); err != nil {
				logrus.WithError(err).Warn("password validation failed")
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": err})
				return
			}
		}

		if !cacheHit {
			m.Cache.Set(cacheKey, publicCollectionSummary, cache.DefaultExpiration)
		}

		c.Set(auth.PublicAccessKey, ente.PublicAccessContext{
			ID:           publicCollectionSummary.ID,
			IP:           clientIP,
			UserAgent:    userAgent,
			CollectionID: publicCollectionSummary.CollectionID,
		})
		c.Next()
	}
}
func (m *CollectionLinkMiddleware) validateOwnersSubscription(c *gin.Context, cID int64) error {
	userID, err := m.CollectionRepo.GetOwnerID(cID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	err = m.BillingCtrl.HasActiveSelfOrFamilySubscription(userID, false)
	if err != nil {
		return stacktrace.Propagate(err, "failed to validate owners subscription")
	}
	return m.validateOrigin(c, userID)
}

func (m *CollectionLinkMiddleware) isDeviceLimitReached(ctx context.Context,
	collectionSummary ente.PublicCollectionSummary, ip string, ua string) (bool, error) {
	// skip deviceLimit check & record keeping for requests via CF worker
	if network.IsCFWorkerIP(ip) {
		return false, nil
	}

	sharedID := collectionSummary.ID
	hasAccessedInPast, err := m.CollectionLinkRepo.AccessedInPast(ctx, sharedID, ip, ua)
	if err != nil {
		return false, stacktrace.Propagate(err, "")
	}
	// if the device has accessed the url in the past, let it access it now as well, irrespective of device limit.
	if hasAccessedInPast {
		return false, nil
	}
	count, err := m.CollectionLinkRepo.GetUniqueAccessCount(ctx, sharedID)
	if err != nil {
		return false, stacktrace.Propagate(err, "failed to get unique access count")
	}

	deviceLimit := int64(collectionSummary.DeviceLimit)
	if deviceLimit == public2.DeviceLimitThreshold {
		deviceLimit = public2.DeviceLimitThresholdMultiplier * public2.DeviceLimitThreshold
	}

	if count >= public2.DeviceLimitWarningThreshold {
		if !array.Int64InList(sharedID, whitelistedCollectionShareIDs) {
			m.DiscordController.NotifyPotentialAbuse(
				fmt.Sprintf("Album exceeds warning threshold: {CollectionID: %d, ShareID: %d}",
					collectionSummary.CollectionID, collectionSummary.ID))
		}
	}

	if deviceLimit > 0 && count >= deviceLimit {
		return true, nil
	}
	err = m.CollectionLinkRepo.RecordAccessHistory(ctx, sharedID, ip, ua)
	return false, stacktrace.Propagate(err, "failed to record access history")
}

// validatePassword will verify if the user is provided correct password for the public album
func (m *CollectionLinkMiddleware) validatePassword(c *gin.Context, reqPath string,
	collectionSummary ente.PublicCollectionSummary) error {
	if array.StringInList(reqPath, passwordWhiteListedURLs) {
		return nil
	}
	accessTokenJWT := auth.GetAccessTokenJWT(c)
	if accessTokenJWT == "" {
		return ente.ErrAuthenticationRequired
	}
	return m.PublicCollectionCtrl.ValidateJWTToken(c, accessTokenJWT, *collectionSummary.PassHash)
}

func (m *CollectionLinkMiddleware) validateOrigin(c *gin.Context, ownerID int64) error {
	origin := c.Request.Header.Get("Origin")

	if origin == "" || origin == viper.GetString("apps.public-albums") {
		return nil
	}
	reqId := requestid.Get(c)
	logger := logrus.WithFields(logrus.Fields{
		"ownerID": ownerID,
		"req_id":  reqId,
		"origin":  origin,
	})
	alertMessage := fmt.Sprintf("custom domain %s", reqId)
	domain, err := m.RemoteStoreRepo.GetDomain(c, ownerID)
	if err != nil {
		logger.WithError(err).Error("domainFetchFailed")
		m.DiscordController.NotifyPotentialAbuse(alertMessage + " - domainFetchFailed")
		return nil
	}
	if domain == nil || *domain == "" {
		logger.Warn("domainNotConfigured")
		m.DiscordController.NotifyPotentialAbuse(alertMessage + " - domainNotConfigured")
		return ente.NewPermissionDeniedError("no custom domain configured")
	}
	parse, err := url.Parse(origin)
	if err != nil {
		logger.WithError(err).Error("originParseFailedL")
		m.DiscordController.NotifyPotentialAbuse(alertMessage + " - originParseFailed")
		return nil
	}
	if !strings.Contains(strings.ToLower(parse.Host), strings.ToLower(*domain)) {
		logger.Warnf("domainMismatch for owner %d, origin %s, domain %s host %s", ownerID, origin, *domain, parse.Host)
		m.DiscordController.NotifyPotentialAbuse(alertMessage + " - domainMismatch")
		return ente.NewPermissionDeniedError("unknown custom domain")
	}
	return nil
}

func computeHashKeyForList(list []string, delim string) string {
	var buffer bytes.Buffer
	for i := range list {
		buffer.WriteString(list[i])
		buffer.WriteString(delim)
	}
	sha := sha256.Sum256(buffer.Bytes())
	return fmt.Sprintf("%x\n", sha)
}
