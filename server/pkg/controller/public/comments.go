package public

import (
	"context"
	"encoding/json"
	"sort"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/comments"
	"github.com/ente-io/museum/pkg/controller/social"
	"github.com/ente-io/museum/pkg/repo"
	emailUtil "github.com/ente-io/museum/pkg/utils/email"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

const maxCommentPayloadSize = 20 * 1024

// PublicCommentsController handles comments exposed via public collection links.
type PublicCommentsController struct {
	CommentCtrl   *comments.Controller
	CommentsRepo  *repo.CommentsRepository
	ReactionsRepo *repo.ReactionsRepository
	UserRepo      *repo.UserRepository
	UserAuthRepo  *repo.UserAuthRepository
	JwtSecret     []byte
}

// CommentRequest models incoming payload for creating a comment.
type CommentRequest struct {
	ID              string          `json:"id" binding:"required"`
	FileID          *int64          `json:"fileID"`
	ParentCommentID *string         `json:"parentCommentID"`
	Payload         json.RawMessage `json:"payload" binding:"required"`
	AnonUserID      *string         `json:"anonUserID"`
	AnonToken       string          `json:"anonToken"`
}

type CommentUpdateRequest struct {
	Payload    json.RawMessage `json:"payload" binding:"required"`
	AnonUserID *string         `json:"anonUserID"`
	AnonToken  string          `json:"anonToken"`
}

type CommentDeleteRequest struct {
	AnonUserID *string `json:"anonUserID"`
	AnonToken  string  `json:"anonToken"`
}

type participant struct {
	EmailMasked string `json:"emailMasked"`
}

func (c *PublicCommentsController) CreateComment(ctx *gin.Context, collectionID int64, req CommentRequest) (string, error) {
	if len(req.Payload) == 0 || len(req.Payload) > maxCommentPayloadSize {
		return "", ente.ErrBadRequest
	}
	actor, err := resolvePublicActor(ctx, c.UserAuthRepo, c.JwtSecret, req.AnonUserID, req.AnonToken, true)
	if err != nil {
		return "", err
	}
	createReq := comments.CreateCommentRequest{
		Actor:           actor,
		CollectionID:    collectionID,
		FileID:          req.FileID,
		ParentCommentID: req.ParentCommentID,
		Payload:         req.Payload,
		ID:              req.ID,
		RequireAccess:   false,
	}
	return c.CommentCtrl.Create(ctx, createReq)
}

func (c *PublicCommentsController) UpdateComment(ctx *gin.Context, collectionID int64, commentID string, req CommentUpdateRequest) error {
	if len(req.Payload) == 0 || len(req.Payload) > maxCommentPayloadSize {
		return ente.ErrBadRequest
	}
	actor, err := resolvePublicActor(ctx, c.UserAuthRepo, c.JwtSecret, req.AnonUserID, req.AnonToken, true)
	if err != nil {
		return err
	}
	updateReq := comments.UpdateCommentRequest{
		Actor:     actor,
		CommentID: commentID,
		Payload:   req.Payload,
	}
	return c.CommentCtrl.UpdatePayload(ctx, updateReq)
}

func (c *PublicCommentsController) DeleteComment(ctx *gin.Context, collectionID int64, commentID string, req CommentDeleteRequest) error {
	actor, err := resolvePublicActor(ctx, c.UserAuthRepo, c.JwtSecret, req.AnonUserID, req.AnonToken, true)
	if err != nil {
		return err
	}
	deleteReq := comments.DeleteCommentRequest{
		Actor:         actor,
		CommentID:     commentID,
		RequireAccess: false,
	}
	return c.CommentCtrl.Delete(ctx, deleteReq)
}

func (c *PublicCommentsController) ListComments(ctx *gin.Context, collectionID int64, since int64, limit int, fileID *int64) ([]ente.Comment, bool, error) {
	diffReq := comments.DiffRequest{
		Actor:         social.Actor{},
		CollectionID:  collectionID,
		Since:         since,
		Limit:         limit,
		FileID:        fileID,
		RequireAccess: false,
	}
	return c.CommentCtrl.Diff(ctx, diffReq)
}

func (c *PublicCommentsController) Participants(ctx context.Context, collectionID int64) ([]participant, error) {
	ids := map[int64]struct{}{}
	commentIDs, err := c.CommentsRepo.GetActiveUserIDs(ctx, collectionID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	for _, id := range commentIDs {
		ids[id] = struct{}{}
	}
	reactionIDs, err := c.ReactionsRepo.GetActiveUserIDs(ctx, collectionID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	for _, id := range reactionIDs {
		ids[id] = struct{}{}
	}
	masked := make([]string, 0, len(ids))
	for id := range ids {
		user, err := c.UserRepo.GetUserByIDInternal(id)
		if err != nil {
			continue
		}
		masked = append(masked, emailUtil.GetMaskedEmail(user.Email))
	}
	sort.Strings(masked)
	participants := make([]participant, len(masked))
	for idx, maskedEmail := range masked {
		participants[idx] = participant{EmailMasked: maskedEmail}
	}
	return participants, nil
}
