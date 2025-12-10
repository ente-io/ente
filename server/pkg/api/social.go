package api

import (
	"net/http"
	"strconv"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/social"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// SocialHandler exposes unified diff and counts endpoints.
type SocialHandler struct {
	Controller *social.Controller
}

func (h *SocialHandler) UnifiedDiff(c *gin.Context) {
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
	userID := auth.GetUserID(c.Request.Header)
	if userID <= 0 {
		handler.Error(c, ente.ErrAuthenticationRequired)
		return
	}
	req := social.UnifiedDiffRequest{
		Actor:         social.Actor{UserID: &userID},
		CollectionID:  collectionID,
		Since:         since,
		Limit:         limit,
		FileID:        fileID,
		RequireAccess: true,
	}
	comments, reactions, hasMoreComments, hasMoreReactions, err := h.Controller.UnifiedDiff(c, req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"comments":         comments,
		"reactions":        reactions,
		"hasMoreComments":  hasMoreComments,
		"hasMoreReactions": hasMoreReactions,
	})
}

func (h *SocialHandler) Counts(c *gin.Context) {
	userID := auth.GetUserID(c.Request.Header)
	if userID <= 0 {
		handler.Error(c, ente.ErrAuthenticationRequired)
		return
	}
	counts, err := h.Controller.CountActiveCollections(c.Request.Context(), userID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{"counts": counts})
}

func (h *SocialHandler) AnonProfiles(c *gin.Context) {
	collectionID, err := strconv.ParseInt(c.Query("collectionID"), 10, 64)
	if err != nil || collectionID <= 0 {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "invalid collectionID"))
		return
	}
	userID := auth.GetUserID(c.Request.Header)
	if userID <= 0 {
		handler.Error(c, ente.ErrAuthenticationRequired)
		return
	}
	profiles, err := h.Controller.ListAnonProfiles(c, social.AnonProfilesRequest{
		Actor:         social.Actor{UserID: &userID},
		CollectionID:  collectionID,
		RequireAccess: true,
	})
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{"profiles": profiles})
}
