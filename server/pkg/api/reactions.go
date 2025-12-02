package api

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/reactions"
	"github.com/ente-io/museum/pkg/controller/social"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

const maxReactionPayloadBytes = 2 * 1024

// ReactionsHandler exposes authenticated reaction APIs.
type ReactionsHandler struct {
	Controller *reactions.Controller
}

type reactionPayload struct {
	ID           string          `json:"id" binding:"required"`
	CollectionID int64           `json:"collectionID" binding:"required"`
	FileID       *int64          `json:"fileID"`
	CommentID    *string         `json:"commentID"`
	Payload      json.RawMessage `json:"payload" binding:"required"`
}

func (h *ReactionsHandler) Upsert(c *gin.Context) {
	var payload reactionPayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	if len(payload.Payload) == 0 || len(payload.Payload) > maxReactionPayloadBytes {
		handler.Error(c, ente.ErrBadRequest)
		return
	}
	if payload.FileID != nil && payload.CommentID != nil {
		handler.Error(c, ente.ErrBadRequest)
		return
	}
	userID := auth.GetUserID(c.Request.Header)
	if userID <= 0 {
		handler.Error(c, ente.ErrAuthenticationRequired)
		return
	}
	req := reactions.UpsertReactionRequest{
		Actor:         social.Actor{UserID: &userID},
		ID:            payload.ID,
		CollectionID:  payload.CollectionID,
		FileID:        payload.FileID,
		CommentID:     payload.CommentID,
		Payload:       payload.Payload,
		RequireAccess: true,
	}
	id, err := h.Controller.Upsert(c, req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{"id": id})
}

func (h *ReactionsHandler) Diff(c *gin.Context) {
	collectionID, err := strconv.ParseInt(c.Query("collectionID"), 10, 64)
	if err != nil || collectionID <= 0 {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "invalid collectionID"))
		return
	}
	since, err := parseDiffSinceTime(c.Query("sinceTime"))
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	limit, err := parseDiffLimit(c.Query("limit"))
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	fileID, err := parseOptionalInt64(c.Query("fileID"))
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	commentIDRaw := c.Query("commentID")
	var commentID *string
	if commentIDRaw != "" {
		commentID = &commentIDRaw
	}
	userID := auth.GetUserID(c.Request.Header)
	if userID <= 0 {
		handler.Error(c, ente.ErrAuthenticationRequired)
		return
	}
	req := reactions.DiffRequest{
		Actor:         social.Actor{UserID: &userID},
		CollectionID:  collectionID,
		Since:         since,
		Limit:         limit,
		FileID:        fileID,
		CommentID:     commentID,
		RequireAccess: true,
	}
	resp, hasMore, err := h.Controller.Diff(c, req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{"reactions": resp, "hasMore": hasMore})
}

func (h *ReactionsHandler) Delete(c *gin.Context) {
	reactionID := c.Param("reactionID")
	if reactionID == "" {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "reactionID required"))
		return
	}
	userID := auth.GetUserID(c.Request.Header)
	if userID <= 0 {
		handler.Error(c, ente.ErrAuthenticationRequired)
		return
	}
	req := reactions.DeleteRequest{
		Actor:         social.Actor{UserID: &userID},
		ReactionID:    reactionID,
		RequireAccess: true,
	}
	if err := h.Controller.Delete(c, req); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{})
}
