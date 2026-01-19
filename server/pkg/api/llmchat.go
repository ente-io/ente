package api

import (
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"

	"github.com/ente-io/museum/ente"
	model "github.com/ente-io/museum/ente/llmchat"
	llmchat "github.com/ente-io/museum/pkg/controller/llmchat"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-contrib/requestid"
	"github.com/gin-gonic/gin"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/sirupsen/logrus"
)

// LlmChatHandler expose request handlers for llm chat endpoints.
type LlmChatHandler struct {
	Controller           *llmchat.Controller
	AttachmentController *llmchat.AttachmentController
}

const (
	llmChatEndpointUpsertKey          = "upsert_key"
	llmChatEndpointGetKey             = "get_key"
	llmChatEndpointUpsertSession      = "upsert_session"
	llmChatEndpointUpsertMessage      = "upsert_message"
	llmChatEndpointDeleteSession      = "delete_session"
	llmChatEndpointDeleteMessage      = "delete_message"
	llmChatEndpointGetDiff            = "get_diff"
	llmChatEndpointUploadAttachment   = "upload_attachment"
	llmChatEndpointDownloadAttachment = "download_attachment"

	llmChatMaxJSONBodyBytes = int64(800 * 1024) // 800KB
)

var (
	llmChatLatency = promauto.NewHistogramVec(prometheus.HistogramOpts{
		Name:    "museum_llm_chat_latency_ms",
		Help:    "Latency of llm chat endpoints in milliseconds",
		Buckets: []float64{10, 50, 100, 200, 500, 1000, 10000, 30000, 60000, 120000, 600000},
	}, []string{"endpoint", "status"})
	llmChatRequests = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "museum_llm_chat_requests_total",
		Help: "Total number of llm chat requests by endpoint and result",
	}, []string{"endpoint", "result"})
	llmChatDiffItems = promauto.NewCounterVec(prometheus.CounterOpts{
		Name: "museum_llm_chat_diff_items_total",
		Help: "Number of llm chat diff items returned",
	}, []string{"entity"})
)

func observeLlmChatMetrics(c *gin.Context, endpoint string, startTime time.Time) {
	statusCode := c.Writer.Status()
	result := "success"
	if statusCode >= http.StatusBadRequest {
		result = "error"
	}
	llmChatRequests.WithLabelValues(endpoint, result).Inc()
	llmChatLatency.WithLabelValues(endpoint, strconv.Itoa(statusCode)).
		Observe(float64(time.Since(startTime).Milliseconds()))
}

func observeLlmChatDiffMetrics(resp *model.GetDiffResponse) {
	if resp == nil {
		return
	}
	llmChatDiffItems.WithLabelValues("sessions").Add(float64(len(resp.Sessions)))
	llmChatDiffItems.WithLabelValues("messages").Add(float64(len(resp.Messages)))
	llmChatDiffItems.WithLabelValues("session_tombstones").Add(float64(len(resp.Tombstones.Sessions)))
	llmChatDiffItems.WithLabelValues("message_tombstones").Add(float64(len(resp.Tombstones.Messages)))
}

func logLlmChatDiff(c *gin.Context, req model.GetDiffRequest, resp *model.GetDiffResponse) {
	if resp == nil {
		return
	}
	sessions := len(resp.Sessions)
	messages := len(resp.Messages)
	sessionTombstones := len(resp.Tombstones.Sessions)
	messageTombstones := len(resp.Tombstones.Messages)
	total := sessions + messages + sessionTombstones + messageTombstones
	sinceTime := int64(0)
	if req.SinceTime != nil {
		sinceTime = *req.SinceTime
	}
	logrus.WithFields(logrus.Fields{
		"req_id":             requestid.Get(c),
		"user_id":            auth.GetUserID(c.Request.Header),
		"since_time":         sinceTime,
		"limit":              req.Limit,
		"sessions":           sessions,
		"messages":           messages,
		"session_tombstones": sessionTombstones,
		"message_tombstones": messageTombstones,
		"total":              total,
		"timestamp":          resp.Timestamp,
	}).Info("llm chat diff served")
}

func bindJSONWithLimit(c *gin.Context, out interface{}, maxBytes int64) error {
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxBytes)
	if err := c.ShouldBindJSON(out); err != nil {
		var maxErr *http.MaxBytesError
		if errors.As(err, &maxErr) {
			return &ente.ErrLlmChatPayloadTooLarge
		}
		return stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err))
	}
	return nil
}

func (h *LlmChatHandler) UpsertKey(c *gin.Context) {
	startTime := time.Now()
	defer observeLlmChatMetrics(c, llmChatEndpointUpsertKey, startTime)

	var request model.UpsertKeyRequest
	if err := bindJSONWithLimit(c, &request, llmChatMaxJSONBodyBytes); err != nil {
		handler.Error(c, err)
		return
	}
	resp, err := h.Controller.UpsertKey(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to upsert llm chat key"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *LlmChatHandler) GetKey(c *gin.Context) {
	startTime := time.Now()
	defer observeLlmChatMetrics(c, llmChatEndpointGetKey, startTime)

	resp, err := h.Controller.GetKey(c)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to get llm chat key"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *LlmChatHandler) UpsertSession(c *gin.Context) {
	startTime := time.Now()
	defer observeLlmChatMetrics(c, llmChatEndpointUpsertSession, startTime)

	var request model.UpsertSessionRequest
	if err := bindJSONWithLimit(c, &request, llmChatMaxJSONBodyBytes); err != nil {
		handler.Error(c, err)
		return
	}
	resp, err := h.Controller.UpsertSession(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to upsert llm chat session"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *LlmChatHandler) UpsertMessage(c *gin.Context) {
	startTime := time.Now()
	defer observeLlmChatMetrics(c, llmChatEndpointUpsertMessage, startTime)

	var request model.UpsertMessageRequest
	if err := bindJSONWithLimit(c, &request, llmChatMaxJSONBodyBytes); err != nil {
		handler.Error(c, err)
		return
	}
	resp, err := h.Controller.UpsertMessage(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to upsert llm chat message"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *LlmChatHandler) DeleteSession(c *gin.Context) {
	startTime := time.Now()
	defer observeLlmChatMetrics(c, llmChatEndpointDeleteSession, startTime)

	sessionUUID := c.Query("id")
	if sessionUUID == "" {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Missing session id"))
		return
	}
	resp, err := h.Controller.DeleteSession(c, sessionUUID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to delete llm chat session"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *LlmChatHandler) DeleteMessage(c *gin.Context) {
	startTime := time.Now()
	defer observeLlmChatMetrics(c, llmChatEndpointDeleteMessage, startTime)

	messageUUID := c.Query("id")
	if messageUUID == "" {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Missing message id"))
		return
	}
	resp, err := h.Controller.DeleteMessage(c, messageUUID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to delete llm chat message"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *LlmChatHandler) UploadAttachment(c *gin.Context) {
	startTime := time.Now()
	defer observeLlmChatMetrics(c, llmChatEndpointUploadAttachment, startTime)

	if h.AttachmentController == nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrNotImplemented, "Attachments not configured"))
		return
	}

	attachmentID := c.Param("attachmentId")
	if attachmentID == "" {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Missing attachment id"))
		return
	}
	if _, err := uuid.Parse(attachmentID); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Invalid attachment id"))
		return
	}

	err := h.AttachmentController.Upload(c, attachmentID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to upload attachment"))
		return
	}

	c.Status(http.StatusNoContent)
}

func (h *LlmChatHandler) DownloadAttachment(c *gin.Context) {
	startTime := time.Now()
	defer observeLlmChatMetrics(c, llmChatEndpointDownloadAttachment, startTime)

	if h.AttachmentController == nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrNotImplemented, "Attachments not configured"))
		return
	}

	attachmentID := c.Param("attachmentId")
	if attachmentID == "" {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Missing attachment id"))
		return
	}
	if _, err := uuid.Parse(attachmentID); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Invalid attachment id"))
		return
	}

	body, size, err := h.AttachmentController.Download(c, attachmentID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to download attachment"))
		return
	}
	defer body.Close()

	c.DataFromReader(http.StatusOK, size, "application/octet-stream", body, nil)
}

func (h *LlmChatHandler) GetDiff(c *gin.Context) {
	startTime := time.Now()
	defer observeLlmChatMetrics(c, llmChatEndpointGetDiff, startTime)

	var request model.GetDiffRequest
	if err := c.ShouldBindQuery(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	if request.Limit <= 0 {
		request.Limit = 500
	}
	resp, err := h.Controller.GetDiff(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to fetch llm chat diff"))
		return
	}
	observeLlmChatDiffMetrics(resp)
	logLlmChatDiff(c, request, resp)
	c.JSON(http.StatusOK, resp)
}
