package middleware

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"sync/atomic"
	"time"

	"github.com/ente-io/museum/pkg/controller/discord"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/network"

	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
	"github.com/ulule/limiter/v3"
	"github.com/ulule/limiter/v3/drivers/store/memory"
)

type RateLimitMiddleware struct {
	count             int64 // Use int64 for atomic operations
	limit             int64
	reset             time.Duration
	ticker            *time.Ticker
	limit10ReqPerMin  *limiter.Limiter
	limit200ReqPerSec *limiter.Limiter
	discordCtrl       *discord.DiscordController
}

func NewRateLimitMiddleware(discordCtrl *discord.DiscordController, limit int64, reset time.Duration) *RateLimitMiddleware {
	rl := &RateLimitMiddleware{
		limit10ReqPerMin:  rateLimiter("10-M"),
		limit200ReqPerSec: rateLimiter("200-S"),
		discordCtrl:       discordCtrl,
		limit:             limit,
		reset:             reset,
		ticker:            time.NewTicker(reset),
	}
	go func() {
		for range rl.ticker.C {
			atomic.StoreInt64(&rl.count, 0) // Reset the count every reset interval
		}
	}()
	return rl
}

// Increment increments the counter in a thread-safe manner.
// Returns true if the increment was within the rate limit, false if the rate limit was exceeded.
func (r *RateLimitMiddleware) Increment() bool {
	// Atomically increment the count
	newCount := atomic.AddInt64(&r.count, 1)
	return newCount <= r.limit
}

// Stop the internal ticker, effectively stopping the rate limiter.
func (r *RateLimitMiddleware) Stop() {
	r.ticker.Stop()
}

// rateLimiter will return instance of limiter.Limiter based on internal <limit>-<period>
// Examples: 5 reqs/sec: "5-S", 10 reqs/min: "10-M"
// 1000 reqs/hour: "1000-H", 2000 reqs/day: "2000-D"
// https://github.com/ulule/limiter/
func rateLimiter(interval string) *limiter.Limiter {
	store := memory.NewStore()
	rate, err := limiter.NewRateFromFormatted(interval)
	if err != nil {
		panic(err)
	}
	instance := limiter.New(store, rate)
	return instance
}

// GlobalRateLimiter rate limits all requests to the server, regardless of the endpoint.
func (r *RateLimitMiddleware) GlobalRateLimiter() gin.HandlerFunc {
	return func(c *gin.Context) {
		if !r.Increment() {
			if r.count%100 == 0 {
				go r.discordCtrl.NotifyPotentialAbuse(fmt.Sprintf("Global ratelimit (%d) breached %d", r.limit, r.count))
			}
			c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{"error": "Rate limit breached, try later"})
			return
		}
		c.Next()
	}
}

// APIRateLimitMiddleware only rate limits sensitive public endpoints which have a higher risk
// of abuse by any bad actor.
func (r *RateLimitMiddleware) APIRateLimitMiddleware(urlSanitizer func(_ *gin.Context) string) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestPath := urlSanitizer(c)
		rateLimiter := r.getLimiter(requestPath, c.Request.Method)
		if rateLimiter != nil {
			key := fmt.Sprintf("%s-%s", network.GetClientIP(c), requestPath)
			limitContext, err := rateLimiter.Get(c, key)
			if err != nil {
				log.Error("Failed to check rate limit", err)
				c.Next() // assume that limit hasn't reached
				return
			}
			if limitContext.Reached {
				go r.discordCtrl.NotifyPotentialAbuse(fmt.Sprintf("Rate limit breached %s", requestPath))
				log.Error(fmt.Sprintf("Rate limit breached %s", key))
				c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{"error": "Rate limit breached, try later"})
				return
			}
		}
		c.Next()
	}
}

// APIRateLimitForUserMiddleware only rate limits sensitive authenticated endpoints which have a higher risk
// of abuse by any bad actor.
func (r *RateLimitMiddleware) APIRateLimitForUserMiddleware(urlSanitizer func(_ *gin.Context) string) gin.HandlerFunc {
	return func(c *gin.Context) {
		requestPath := urlSanitizer(c)
		rateLimiter := r.getLimiter(requestPath, c.Request.Method)
		if rateLimiter != nil {
			userID := auth.GetUserID(c.Request.Header)
			if userID == 0 {
				// do not apply limit, just log
				log.Error("userID must be present in request header for applying rate-limit")
				return
			}
			limitContext, err := rateLimiter.Get(c, strconv.FormatInt(userID, 10))
			if err != nil {
				log.Error("Failed to check rate limit", err)
				c.Next() // assume that limit hasn't reached
				return
			}
			if limitContext.Reached {
				msg := fmt.Sprintf("Rate limit breached %d for path: %s", userID, requestPath)
				go r.discordCtrl.NotifyPotentialAbuse(msg)
				log.Error(msg)
				c.AbortWithStatusJSON(http.StatusTooManyRequests, gin.H{"error": "Rate limit breached, try later"})
				return
			}
		}
		c.Next()
	}
}

// getLimiter, based on reqPath & reqMethod, return instance of limiter.Limiter which needs to
// be applied for a request. It returns nil if the request is not rate limited
func (r *RateLimitMiddleware) getLimiter(reqPath string, reqMethod string) *limiter.Limiter {
	if reqPath == "/users/ott" ||
		reqPath == "/users/verify-email" ||
		reqPath == "/public-collection/verify-password" ||
		reqPath == "/family/accept-invite" ||
		reqPath == "/users/srp/attributes" ||
		(reqPath == "/cast/device-info" && reqMethod == "POST") ||
		(reqPath == "/cast/device-info/" && reqMethod == "POST") ||
		reqPath == "/users/srp/create-session" ||
		reqPath == "/users/srp/verify-session" ||
		reqPath == "/family/invite-info/:token" ||
		reqPath == "/family/add-member" ||
		strings.HasPrefix(reqPath, "/users/srp/") ||
		strings.HasPrefix(reqPath, "/users/two-factor/") {
		return r.limit10ReqPerMin
	} else if reqPath == "/files/preview" {
		return r.limit200ReqPerSec
	}
	return nil
}
