package middleware

import (
	"bytes"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/museum/pkg/utils/network"
	timeUtil "github.com/ente-io/museum/pkg/utils/time"
	"github.com/gin-contrib/requestid"
	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/sirupsen/logrus"
)

var latency = promauto.NewHistogramVec(prometheus.HistogramOpts{
	Name:    "museum_latency",
	Help:    "The amount of time the server is taking to respond to requests",
	Buckets: []float64{10, 50, 100, 200, 500, 1000, 10000, 30000, 60000, 120000, 600000},
}, []string{"code", "method", "host", "url"})

// shouldSkipBodyLog returns true if the body should not be logged.
// This is useful for endpoints that receive large or sensitive payloads.
func shouldSkipBodyLog(method string, path string) bool {
	if method == http.MethodPut && path == "/embeddings" {
		return true
	}
	if path == "/user-entity/entity" && (method == http.MethodPost || method == http.MethodPut) {
		return true
	}
	if path == "/files/data" && method == http.MethodPut {
		return true
	}
	if path == "/admin/user/terminate-session" {
		return true
	}
	if strings.HasPrefix(path, "/llmchat/chat/attachment/") && method == http.MethodPut {
		return true
	}
	if path == "/llmchat/chat/message" && method == http.MethodPost {
		return true
	}
	if path == "/llmchat/chat/session" && method == http.MethodPost {
		return true
	}
	if path == "/llmchat/chat/key" && method == http.MethodPost {
		return true
	}
	return false
}

// Logger logs the details regarding an incoming request
func Logger(urlSanitizer func(_ *gin.Context) string) gin.HandlerFunc {
	return func(c *gin.Context) {
		startTime := time.Now()
		reqID := requestid.Get(c)

		userAgent := c.GetHeader("User-Agent")
		clientVersion := c.GetHeader("X-Client-Version")
		clientPkg := c.GetHeader("X-Client-Package")
		clientIP := network.GetClientIP(c)
		reqMethod := c.Request.Method
		reqPath := c.Request.URL.Path

		queryValues, _ := url.ParseQuery(c.Request.URL.RawQuery)
		if queryValues.Has("token") {
			queryValues.Set("token", "redacted-value")
		}
		queryParamsForLog := queryValues.Encode()

		reqContextLogger := logrus.WithFields(logrus.Fields{
			"client_ip":      clientIP,
			"client_pkg":     clientPkg,
			"client_version": clientVersion,
			"query":          queryParamsForLog,
			"req_id":         reqID,
			"req_method":     reqMethod,
			"req_uri":        reqPath,
			"ua":             userAgent,
		})

		skipBodyLog := shouldSkipBodyLog(reqMethod, reqPath)
		body := ""
		if skipBodyLog {
			reqContextLogger = reqContextLogger.WithField("req_body", "redacted")
		} else {
			buf, err := io.ReadAll(c.Request.Body)
			if err != nil {
				handler.Error(c, err)
				return
			}
			body = string(buf)
			c.Request.Body = io.NopCloser(bytes.NewBuffer(buf))
			reqContextLogger = reqContextLogger.WithField("req_body", body)
		}

		reqContextLogger.Info("incoming")

		c.Next()

		statusCode := c.Writer.Status()
		latencyTime := time.Since(startTime)
		reqURI := urlSanitizer(c)
		if reqMethod != http.MethodOptions {
			latency.WithLabelValues(strconv.Itoa(statusCode), reqMethod, c.Request.Host, reqURI).
				Observe(float64(latencyTime.Milliseconds()))
		}

		if statusCode >= 400 && !skipBodyLog {
			reqContextLogger = reqContextLogger.WithField("req_body", body)
		}

		reqContextLogger.WithFields(logrus.Fields{
			"latency_time": latencyTime,
			"h_latency":    timeUtil.HumanFriendlyDuration(latencyTime),
			"status_code":  statusCode,
			"user_id":      auth.GetUserID(c.Request.Header),
		}).Info("outgoing")
	}
}
