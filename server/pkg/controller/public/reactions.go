package public

import (
	"encoding/json"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/reactions"
	"github.com/ente-io/museum/pkg/controller/social"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/gin-gonic/gin"
)

const maxReactionPayloadSize = 2 * 1024

// PublicReactionsController exposes reactions for public collections.
type PublicReactionsController struct {
	ReactionCtrl  *reactions.Controller
	ReactionsRepo *repo.ReactionsRepository
	UserAuthRepo  *repo.UserAuthRepository
	JwtSecret     []byte
}

type ReactionRequest struct {
	ID         string          `json:"id" binding:"required"`
	FileID     *int64          `json:"fileID"`
	CommentID  *string         `json:"commentID"`
	Payload    json.RawMessage `json:"payload" binding:"required"`
	AnonUserID *string         `json:"anonUserID"`
	AnonToken  string          `json:"anonToken"`
}

type ReactionDeleteRequest struct {
	AnonUserID *string `json:"anonUserID"`
	AnonToken  string  `json:"anonToken"`
}

func (c *PublicReactionsController) UpsertReaction(ctx *gin.Context, collectionID int64, req ReactionRequest) (string, error) {
	if len(req.Payload) == 0 || len(req.Payload) > maxReactionPayloadSize {
		return "", ente.ErrBadRequest
	}
	if req.FileID != nil && req.CommentID != nil {
		return "", ente.ErrBadRequest
	}
	actor, err := resolvePublicActor(ctx, c.UserAuthRepo, c.JwtSecret, req.AnonUserID, req.AnonToken, true)
	if err != nil {
		return "", err
	}
	upsertReq := reactions.UpsertReactionRequest{
		Actor:         actor,
		ID:            req.ID,
		CollectionID:  collectionID,
		FileID:        req.FileID,
		CommentID:     req.CommentID,
		Payload:       req.Payload,
		RequireAccess: false,
	}
	return c.ReactionCtrl.Upsert(ctx, upsertReq)
}

func (c *PublicReactionsController) DeleteReaction(ctx *gin.Context, collectionID int64, reactionID string, req ReactionDeleteRequest) error {
	actor, err := resolvePublicActor(ctx, c.UserAuthRepo, c.JwtSecret, req.AnonUserID, req.AnonToken, true)
	if err != nil {
		return err
	}
	deleteReq := reactions.DeleteRequest{
		Actor:         actor,
		ReactionID:    reactionID,
		RequireAccess: false,
	}
	return c.ReactionCtrl.Delete(ctx, deleteReq)
}

func (c *PublicReactionsController) ListReactions(ctx *gin.Context, collectionID int64, since int64, limit int, fileID *int64, commentID *string) ([]ente.Reaction, bool, error) {
	diffReq := reactions.DiffRequest{
		Actor:         social.Actor{},
		CollectionID:  collectionID,
		Since:         since,
		Limit:         limit,
		FileID:        fileID,
		CommentID:     commentID,
		RequireAccess: false,
	}
	return c.ReactionCtrl.Diff(ctx, diffReq)
}
