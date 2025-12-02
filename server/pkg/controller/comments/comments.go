package comments

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/access"
	"github.com/ente-io/museum/pkg/controller/social"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// Controller wires comment-specific business logic.
type Controller struct {
	Repo       *repo.CommentsRepository
	AccessCtrl access.Controller
}

// CreateCommentRequest encapsulates parameters for adding a comment.
type CreateCommentRequest struct {
	Actor           social.Actor
	CollectionID    int64
	FileID          *int64
	ParentCommentID *string
	Payload         []byte
	ID              string
	RequireAccess   bool
}

// DiffRequest describes the paging request for a collection's comments.
type DiffRequest struct {
	Actor         social.Actor
	CollectionID  int64
	Since         int64
	Limit         int
	FileID        *int64
	RequireAccess bool
}

// UpdateCommentRequest holds the information needed to edit a comment.
type UpdateCommentRequest struct {
	Actor         social.Actor
	CommentID     string
	Payload       []byte
	RequireAccess bool
}

// DeleteCommentRequest defines the delete operation parameters.
type DeleteCommentRequest struct {
	Actor         social.Actor
	CommentID     string
	RequireAccess bool
}

// Create inserts a new comment; returns the supplied ID on success.
func (c *Controller) Create(ctx *gin.Context, req CreateCommentRequest) (string, error) {
	userID, hasUserID := req.Actor.UserIDValue()
	if req.Actor.IsAnonymous() {
		if err := req.Actor.ValidateAnon(); err != nil {
			return "", err
		}
	} else if !hasUserID || userID <= 0 {
		return "", ente.ErrAuthenticationRequired
	}
	if req.RequireAccess && req.Actor.IsAnonymous() {
		return "", ente.ErrPermissionDenied
	}
	if req.RequireAccess {
		if _, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
			CollectionID: req.CollectionID,
			ActorUserID:  userID,
		}); err != nil {
			return "", stacktrace.Propagate(err, "")
		}
	}

	comment := ente.Comment{
		ID:              req.ID,
		CollectionID:    req.CollectionID,
		FileID:          req.FileID,
		ParentCommentID: req.ParentCommentID,
		UserID:          -1,
		AnonUserID:      req.Actor.AnonUserID,
	}
	if hasUserID {
		comment.UserID = userID
	}
	if len(req.Payload) > 0 {
		comment.Payload = req.Payload
	}
	if err := c.Repo.Insert(ctx.Request.Context(), comment); err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	return comment.ID, nil
}

// Diff returns a window of comments for the requested collection.
func (c *Controller) Diff(ctx *gin.Context, req DiffRequest) ([]ente.Comment, bool, error) {
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
	return c.Repo.GetDiff(ctx.Request.Context(), req.CollectionID, req.Since, req.Limit, req.FileID)
}

// UpdatePayload edits the encrypted payload of a comment.
func (c *Controller) UpdatePayload(ctx *gin.Context, req UpdateCommentRequest) error {
	userID, hasUserID := req.Actor.UserIDValue()
	comment, err := c.Repo.GetByID(ctx.Request.Context(), req.CommentID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if req.Actor.IsAnonymous() {
		if err := req.Actor.ValidateAnon(); err != nil {
			return err
		}
		if comment.AnonUserID == nil || req.Actor.AnonUserID == nil || *comment.AnonUserID != *req.Actor.AnonUserID {
			return stacktrace.Propagate(ente.ErrPermissionDenied, "")
		}
	} else if !hasUserID || comment.UserID != userID {
		return stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
	return c.Repo.UpdatePayload(ctx.Request.Context(), req.CommentID, req.Payload)
}

// Delete removes a comment if the actor is allowed to do so.
func (c *Controller) Delete(ctx *gin.Context, req DeleteCommentRequest) error {
	userID, hasUserID := req.Actor.UserIDValue()
	comment, err := c.Repo.GetByID(ctx.Request.Context(), req.CommentID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	switch {
	case req.Actor.IsAnonymous():
		if err := req.Actor.ValidateAnon(); err != nil {
			return err
		}
		if comment.AnonUserID == nil || req.Actor.AnonUserID == nil || *comment.AnonUserID != *req.Actor.AnonUserID {
			return stacktrace.Propagate(ente.ErrPermissionDenied, "")
		}
	default:
		if !hasUserID {
			return stacktrace.Propagate(ente.ErrPermissionDenied, "")
		}
		if comment.UserID == userID {
			// author is allowed
		} else if req.RequireAccess {
			resp, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
				CollectionID: comment.CollectionID,
				ActorUserID:  userID,
			})
			if err != nil {
				return stacktrace.Propagate(err, "")
			}
			if resp.Role == nil {
				return stacktrace.Propagate(ente.ErrPermissionDenied, "")
			}
			minRole := ente.ADMIN
			if !resp.Role.Satisfies(&minRole) {
				return stacktrace.Propagate(ente.ErrPermissionDenied, "")
			}
		} else {
			return stacktrace.Propagate(ente.ErrPermissionDenied, "")
		}
	}
	return c.Repo.SoftDelete(ctx.Request.Context(), req.CommentID)
}
