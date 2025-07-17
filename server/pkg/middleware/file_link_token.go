package middleware

import (
	"context"
	"fmt"
	publicCtrl "github.com/ente-io/museum/pkg/controller/public"
	"github.com/ente-io/museum/pkg/repo/public"
	"net/http"

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

var filePasswordWhiteListedURLs = []string{"/public-collection/info", "/public-collection/report-abuse", "/public-collection/verify-password"}

// FileLinkMiddleware intercepts and authenticates incoming requests
type FileLinkMiddleware struct {
	FileLinkRepo         *public.FileLinkRepository
	PublicCollectionCtrl *publicCtrl.CollectionLinkController
	CollectionRepo       *repo.CollectionRepository
	Cache                *cache.Cache
	BillingCtrl          *controller.BillingController
	DiscordController    *discord.DiscordController
}

// Authenticate returns a middle ware that extracts the `X-Auth-Access-Token`
// within the header of a request and uses it to validate the access token and set the
// ente.PublicAccessContext with auth.PublicAccessKey as key
func (m *FileLinkMiddleware) Authenticate(urlSanitizer func(_ *gin.Context) string) gin.HandlerFunc {
	return func(c *gin.Context) {
		accessToken := auth.GetAccessToken(c)
		if accessToken == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "missing accessToken"})
			return
		}
		clientIP := network.GetClientIP(c)
		userAgent := c.GetHeader("User-Agent")

		cacheKey := computeHashKeyForList([]string{accessToken, clientIP, userAgent}, ":")
		cachedValue, cacheHit := m.Cache.Get(cacheKey)
		var publicCollectionSummary *ente.FileLinkRow
		var err error
		if !cacheHit {
			publicCollectionSummary, err = m.FileLinkRepo.GetFileUrlRowByToken(c, accessToken)
			if err != nil {
				c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
				return
			}
			if publicCollectionSummary.IsDisabled {
				c.AbortWithStatusJSON(http.StatusGone, gin.H{"error": "disabled token"})
				return
			}
			// validate if user still has active paid subscription
			if err = m.BillingCtrl.HasActiveSelfOrFamilySubscription(publicCollectionSummary.OwnerID, true); err != nil {
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
			publicCollectionSummary = cachedValue.(*ente.FileLinkRow)
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

		c.Set(auth.FileLinkAccessKey, &ente.PublicFileAccessContext{
			ID:        publicCollectionSummary.LinkID,
			IP:        clientIP,
			UserAgent: userAgent,
			FileID:    publicCollectionSummary.FileID,
		})
		c.Next()
	}
}
func (m *FileLinkMiddleware) validateOwnersSubscription(cID int64) error {
	userID, err := m.CollectionRepo.GetOwnerID(cID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return m.BillingCtrl.HasActiveSelfOrFamilySubscription(userID, true)
}

func (m *FileLinkMiddleware) isDeviceLimitReached(ctx context.Context,
	collectionSummary *ente.FileLinkRow, ip string, ua string) (bool, error) {
	// skip deviceLimit check & record keeping for requests via CF worker
	if network.IsCFWorkerIP(ip) {
		return false, nil
	}

	sharedID := collectionSummary.LinkID
	hasAccessedInPast, err := m.FileLinkRepo.AccessedInPast(ctx, sharedID, ip, ua)
	if err != nil {
		return false, stacktrace.Propagate(err, "")
	}
	// if the device has accessed the url in the past, let it access it now as well, irrespective of device limit.
	if hasAccessedInPast {
		return false, nil
	}
	count, err := m.FileLinkRepo.GetUniqueAccessCount(ctx, sharedID)
	if err != nil {
		return false, stacktrace.Propagate(err, "failed to get unique access count")
	}

	deviceLimit := int64(collectionSummary.DeviceLimit)
	if deviceLimit == publicCtrl.DeviceLimitThreshold {
		deviceLimit = publicCtrl.DeviceLimitThresholdMultiplier * publicCtrl.DeviceLimitThreshold
	}

	if count >= publicCtrl.DeviceLimitWarningThreshold {
		m.DiscordController.NotifyPotentialAbuse(
			fmt.Sprintf("FileLink exceeds warning threshold: {FileID: %d, ShareID: %s}",
				collectionSummary.FileID, collectionSummary.LinkID))
	}

	if deviceLimit > 0 && count >= deviceLimit {
		return true, nil
	}
	err = m.FileLinkRepo.RecordAccessHistory(ctx, sharedID, ip, ua)
	return false, stacktrace.Propagate(err, "failed to record access history")
}

// validatePassword will verify if the user is provided correct password for the public album
func (m *FileLinkMiddleware) validatePassword(c *gin.Context, reqPath string,
	fileLinkRow *ente.FileLinkRow) error {
	if array.StringInList(reqPath, passwordWhiteListedURLs) {
		return nil
	}
	accessTokenJWT := auth.GetAccessTokenJWT(c)
	if accessTokenJWT == "" {
		return ente.ErrAuthenticationRequired
	}
	return m.PublicCollectionCtrl.ValidateJWTToken(c, accessTokenJWT, *fileLinkRow.PassHash)
}
