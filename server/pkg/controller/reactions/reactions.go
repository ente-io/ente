package reactions

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/access"
	"github.com/ente-io/museum/pkg/controller/social"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// Controller orchestrates reactions operations.
type Controller struct {
	Repo       *repo.ReactionsRepository
	AccessCtrl access.Controller
}

// UpsertReactionRequest holds the payload for creating or updating a reaction.
type UpsertReactionRequest struct {
	Actor         social.Actor
	ID            string
	CollectionID  int64
	FileID        *int64
	CommentID     *string
	Payload       []byte
	RequireAccess bool
}

// DiffRequest describes paging for reactions.
type DiffRequest struct {
	Actor         social.Actor
	CollectionID  int64
	Since         int64
	Limit         int
	FileID        *int64
	CommentID     *string
	RequireAccess bool
}

// DeleteRequest contains parameters to remove a reaction.
type DeleteRequest struct {
	Actor         social.Actor
	ReactionID    string
	RequireAccess bool
}

// Upsert creates or updates a reaction entry.
func (c *Controller) Upsert(ctx *gin.Context, req UpsertReactionRequest) (string, error) {
	userID, hasUserID := req.Actor.UserIDValue()
	if req.RequireAccess && req.Actor.IsAnonymous() {
		return "", ente.ErrAuthenticationRequired
	}
	if req.Actor.IsAnonymous() {
		if err := req.Actor.ValidateAnon(); err != nil {
			return "", err
		}
	} else if !hasUserID || userID <= 0 {
		return "", ente.ErrAuthenticationRequired
	}
	if req.FileID != nil && req.CommentID != nil {
		return "", ente.ErrBadRequest
	}
	if req.RequireAccess {
		if _, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
			CollectionID: req.CollectionID,
			ActorUserID:  userID,
		}); err != nil {
			return "", stacktrace.Propagate(err, "")
		}
	}
	reaction := ente.Reaction{
		ID:           req.ID,
		CollectionID: req.CollectionID,
		FileID:       req.FileID,
		CommentID:    req.CommentID,
		Payload:      req.Payload,
	}
	if req.Actor.IsAnonymous() {
		reaction.UserID = -1
		reaction.AnonUserID = req.Actor.AnonUserID
	} else {
		reaction.UserID = userID
	}
	id, err := c.Repo.Upsert(ctx.Request.Context(), reaction)
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	return id, nil
}

// Diff returns reaction windows for the provided scope.
func (c *Controller) Diff(ctx *gin.Context, req DiffRequest) ([]ente.Reaction, bool, error) {
	userID, hasUserID := req.Actor.UserIDValue()
	if req.RequireAccess {
		if !hasUserID || userID <= 0 {
			return nil, false, ente.ErrAuthenticationRequired
		}
		if _, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
			CollectionID: req.CollectionID,
			ActorUserID:  userID,
		}); err != nil {
			return nil, false, stacktrace.Propagate(err, "")
		}
	}
	return c.Repo.GetDiff(ctx.Request.Context(), req.CollectionID, req.Since, req.Limit, req.FileID, req.CommentID)
}

// Delete removes a reaction if the actor owns it.
func (c *Controller) Delete(ctx *gin.Context, req DeleteRequest) error {
	userID, hasUserID := req.Actor.UserIDValue()
	reaction, err := c.Repo.GetByID(ctx.Request.Context(), req.ReactionID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if req.Actor.IsAnonymous() {
		if err := req.Actor.ValidateAnon(); err != nil {
			return err
		}
		if reaction.AnonUserID == nil || req.Actor.AnonUserID == nil || *reaction.AnonUserID != *req.Actor.AnonUserID {
			return stacktrace.Propagate(ente.ErrPermissionDenied, "")
		}
	} else if !hasUserID || reaction.UserID != userID {
		return stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
	if req.RequireAccess {
		if !hasUserID || userID <= 0 {
			return ente.ErrAuthenticationRequired
		}
		if _, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
			CollectionID: reaction.CollectionID,
			ActorUserID:  userID,
		}); err != nil {
			return stacktrace.Propagate(err, "")
		}
	}
	repoUserID := int64(-1)
	if hasUserID {
		repoUserID = userID
	}
	return c.Repo.SoftDeleteByID(ctx.Request.Context(), req.ReactionID, repoUserID, req.Actor.AnonUserID)
}
