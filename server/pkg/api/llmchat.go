package api

import (
	"errors"
	"fmt"
	"net/http"
	"strconv"

	"github.com/ente-io/museum/ente"
	model "github.com/ente-io/museum/ente/llmchat"
	llmchat "github.com/ente-io/museum/pkg/controller/llmchat"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// LlmChatHandler expose request handlers for llm chat endpoints.
type LlmChatHandler struct {
	Controller           *llmchat.Controller
	AttachmentController *llmchat.AttachmentController
}

const (
	llmChatMaxJSONBodyBytesDefault int64 = 800 * 1024
	llmChatDiffDefaultLimitDefault int16 = 500
	llmChatDiffMaximumLimitDefault int16 = 2500
)

func llmChatMaxJSONBodyBytes() int64 {
	return llmChatMaxJSONBodyBytesDefault
}

func llmChatDiffDefaultLimit() int16 {
	return llmChatDiffDefaultLimitDefault
}

func llmChatDiffMaximumLimit() int16 {
	return llmChatDiffMaximumLimitDefault
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
	var request model.UpsertKeyRequest
	if err := bindJSONWithLimit(c, &request, llmChatMaxJSONBodyBytes()); err != nil {
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
	resp, err := h.Controller.GetKey(c)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to get llm chat key"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

func (h *LlmChatHandler) UpsertSession(c *gin.Context) {
	var request model.UpsertSessionRequest
	if err := bindJSONWithLimit(c, &request, llmChatMaxJSONBodyBytes()); err != nil {
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
	var request model.UpsertMessageRequest
	if err := bindJSONWithLimit(c, &request, llmChatMaxJSONBodyBytes()); err != nil {
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

func (h *LlmChatHandler) GetAttachmentUploadURL(c *gin.Context) {
	if err := h.Controller.ValidateKey(c); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}

	attachmentID := c.Param("attachmentId")
	if attachmentID == "" {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Missing attachment id"))
		return
	}
	var req model.GetAttachmentUploadURLRequest
	if err := bindJSONWithLimit(c, &req, llmChatMaxJSONBodyBytes()); err != nil {
		handler.Error(c, err)
		return
	}

	force := false
	forceParam := c.Query("force")
	if forceParam != "" {
		parsed, err := strconv.ParseBool(forceParam)
		if err != nil {
			handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Invalid force flag"))
			return
		}
		force = parsed
	}

	resp, err := h.AttachmentController.GetUploadURL(c, attachmentID, req, force)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to get attachment upload URL"))
		return
	}

	c.JSON(http.StatusOK, resp)
}

func (h *LlmChatHandler) DownloadAttachment(c *gin.Context) {
	if err := h.Controller.ValidateKey(c); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}

	attachmentID := c.Param("attachmentId")
	if attachmentID == "" {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Missing attachment id"))
		return
	}
	url, err := h.AttachmentController.GetDownloadURL(c, attachmentID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to get attachment download URL"))
		return
	}

	c.Redirect(http.StatusTemporaryRedirect, url)
}

func (h *LlmChatHandler) GetDiff(c *gin.Context) {
	var request model.GetDiffRequest
	if err := c.ShouldBindQuery(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	defaultLimit := llmChatDiffDefaultLimit()
	maxLimit := llmChatDiffMaximumLimit()
	if request.Limit <= 0 {
		request.Limit = defaultLimit
	}
	if request.Limit > maxLimit {
		request.Limit = maxLimit
	}
	resp, err := h.Controller.GetDiff(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to fetch llm chat diff"))
		return
	}
	c.JSON(http.StatusOK, resp)
}
