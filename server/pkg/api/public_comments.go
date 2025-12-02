package api

import (
	"encoding/json"
	"net/http"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/public"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// PublicCommentsHandler handles public collection social APIs.
type PublicCommentsHandler struct {
	CommentsCtrl     *public.PublicCommentsController
	ReactionsCtrl    *public.PublicReactionsController
	AnonIdentityCtrl *public.AnonIdentityController
}

type publicCommentPayload struct {
	ID              string          `json:"id" binding:"required"`
	FileID          *int64          `json:"fileID"`
	ParentCommentID *string         `json:"parentCommentID"`
	Payload         json.RawMessage `json:"payload" binding:"required"`
	AnonUserID      *string         `json:"anonUserID"`
	AnonToken       string          `json:"anonToken"`
}

type publicCommentEditPayload struct {
	Payload    json.RawMessage `json:"payload" binding:"required"`
	AnonUserID *string         `json:"anonUserID"`
	AnonToken  string          `json:"anonToken"`
}

type publicAnonPayload struct {
	AnonUserID *string `json:"anonUserID"`
	AnonToken  string  `json:"anonToken"`
}

type publicReactionPayload struct {
	ID         string          `json:"id" binding:"required"`
	FileID     *int64          `json:"fileID"`
	CommentID  *string         `json:"commentID"`
	Payload    json.RawMessage `json:"payload" binding:"required"`
	AnonUserID *string         `json:"anonUserID"`
	AnonToken  string          `json:"anonToken"`
}

type publicReactionDeletePayload struct {
	AnonUserID *string `json:"anonUserID"`
	AnonToken  string  `json:"anonToken"`
}

func (h *PublicCommentsHandler) CreateComment(c *gin.Context) {
	var payload publicCommentPayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	collectionID := auth.MustGetPublicAccessContext(c).CollectionID
	controllerReq := public.CommentRequest{
		ID:              payload.ID,
		FileID:          payload.FileID,
		ParentCommentID: payload.ParentCommentID,
		Payload:         payload.Payload,
		AnonUserID:      payload.AnonUserID,
		AnonToken:       payload.AnonToken,
	}
	id, err := h.CommentsCtrl.CreateComment(c, collectionID, controllerReq)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusCreated, gin.H{"id": id})
}

func (h *PublicCommentsHandler) UpdateComment(c *gin.Context) {
	var payload publicCommentEditPayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	collectionID := auth.MustGetPublicAccessContext(c).CollectionID
	commentID := c.Param("commentID")
	if commentID == "" {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "missing commentID"))
		return
	}
	controllerReq := public.CommentUpdateRequest{
		Payload:    payload.Payload,
		AnonUserID: payload.AnonUserID,
		AnonToken:  payload.AnonToken,
	}
	if err := h.CommentsCtrl.UpdateComment(c, collectionID, commentID, controllerReq); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{})
}

func (h *PublicCommentsHandler) DeleteComment(c *gin.Context) {
	var payload publicAnonPayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	collectionID := auth.MustGetPublicAccessContext(c).CollectionID
	commentID := c.Param("commentID")
	if commentID == "" {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "missing commentID"))
		return
	}
	controllerReq := public.CommentDeleteRequest{
		AnonUserID: payload.AnonUserID,
		AnonToken:  payload.AnonToken,
	}
	if err := h.CommentsCtrl.DeleteComment(c, collectionID, commentID, controllerReq); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{})
}

func (h *PublicCommentsHandler) CommentDiff(c *gin.Context) {
	collectionID := auth.MustGetPublicAccessContext(c).CollectionID
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
	comments, hasMore, err := h.CommentsCtrl.ListComments(c, collectionID, since, limit, fileID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{"comments": comments, "hasMore": hasMore})
}

func (h *PublicCommentsHandler) CreateReaction(c *gin.Context) {
	var payload publicReactionPayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	collectionID := auth.MustGetPublicAccessContext(c).CollectionID
	controllerReq := public.ReactionRequest{
		ID:         payload.ID,
		FileID:     payload.FileID,
		CommentID:  payload.CommentID,
		Payload:    payload.Payload,
		AnonUserID: payload.AnonUserID,
		AnonToken:  payload.AnonToken,
	}
	id, err := h.ReactionsCtrl.UpsertReaction(c, collectionID, controllerReq)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{"id": id})
}

func (h *PublicCommentsHandler) ReactionDiff(c *gin.Context) {
	collectionID := auth.MustGetPublicAccessContext(c).CollectionID
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
	reactions, hasMore, err := h.ReactionsCtrl.ListReactions(c, collectionID, since, limit, fileID, commentID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{"reactions": reactions, "hasMore": hasMore})
}

func (h *PublicCommentsHandler) DeleteReaction(c *gin.Context) {
	var payload publicReactionDeletePayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	collectionID := auth.MustGetPublicAccessContext(c).CollectionID
	reactionID := c.Param("reactionID")
	if reactionID == "" {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "missing reactionID"))
		return
	}
	controllerReq := public.ReactionDeleteRequest{
		AnonUserID: payload.AnonUserID,
		AnonToken:  payload.AnonToken,
	}
	if err := h.ReactionsCtrl.DeleteReaction(c, collectionID, reactionID, controllerReq); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{})
}

func (h *PublicCommentsHandler) Participants(c *gin.Context) {
	collectionID := auth.MustGetPublicAccessContext(c).CollectionID
	// ignore includeSharees flag for now
	participants, err := h.CommentsCtrl.Participants(c.Request.Context(), collectionID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{"participants": participants})
}

func (h *PublicCommentsHandler) CreateAnonIdentity(c *gin.Context) {
	resp, err := h.AnonIdentityCtrl.Create(c)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusCreated, resp)
}
