package public

import (
	"context"
	"sort"

	"github.com/ente-io/museum/ente"
	socialentity "github.com/ente-io/museum/ente/social"
	socialcontroller "github.com/ente-io/museum/pkg/controller/social"
	"github.com/ente-io/museum/pkg/repo"
	socialrepo "github.com/ente-io/museum/pkg/repo/social"
	emailUtil "github.com/ente-io/museum/pkg/utils/email"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

const maxCommentPayloadSize = 20 * 1024

// CommentsController handles comments exposed via public collection links.
type CommentsController struct {
	CommentCtrl   *socialcontroller.CommentsController
	CommentsRepo  *socialrepo.CommentsRepository
	ReactionsRepo *socialrepo.ReactionsRepository
	UserRepo      *repo.UserRepository
	UserAuthRepo  *repo.UserAuthRepository
	AnonUsersRepo *socialrepo.AnonUsersRepository
	JwtSecret     []byte
}

// CommentRequest models incoming payload for creating a comment.
type CommentRequest struct {
	ID              string  `json:"id"`
	FileID          *int64  `json:"fileID"`
	ParentCommentID *string `json:"parentCommentID"`
	Cipher          string  `json:"cipher" binding:"required"`
	Nonce           string  `json:"nonce" binding:"required"`
	AnonUserID      *string `json:"anonUserID"`
	AnonToken       string  `json:"anonToken"`
}

type CommentUpdateRequest struct {
	Cipher     string  `json:"cipher" binding:"required"`
	Nonce      string  `json:"nonce" binding:"required"`
	AnonUserID *string `json:"anonUserID"`
	AnonToken  string  `json:"anonToken"`
}

type CommentDeleteRequest struct {
	AnonUserID *string `json:"anonUserID"`
	AnonToken  string  `json:"anonToken"`
}

type participant struct {
	EmailMasked string `json:"emailMasked"`
}

func (c *CommentsController) CreateComment(ctx *gin.Context, collectionID int64, req CommentRequest) (string, error) {
	if len(req.Cipher) == 0 || len(req.Cipher) > maxCommentPayloadSize {
		return "", ente.ErrBadRequest
	}
	if len(req.Nonce) == 0 {
		return "", ente.ErrBadRequest
	}
	actor, err := resolvePublicActor(ctx, c.UserAuthRepo, c.JwtSecret, req.AnonUserID, req.AnonToken, true)
	if err != nil {
		return "", err
	}
	if err := ensureAnonUserForCollection(ctx.Request.Context(), c.AnonUsersRepo, collectionID, actor); err != nil {
		return "", err
	}
	createReq := socialcontroller.CreateCommentRequest{
		Actor:           actor,
		CollectionID:    collectionID,
		FileID:          req.FileID,
		ParentCommentID: req.ParentCommentID,
		Cipher:          req.Cipher,
		Nonce:           req.Nonce,
		ID:              req.ID,
		RequireAccess:   false,
	}
	return c.CommentCtrl.Create(ctx, createReq)
}

func (c *CommentsController) UpdateComment(ctx *gin.Context, collectionID int64, commentID string, req CommentUpdateRequest) error {
	if len(req.Cipher) == 0 || len(req.Cipher) > maxCommentPayloadSize {
		return ente.ErrBadRequest
	}
	if len(req.Nonce) == 0 {
		return ente.ErrBadRequest
	}
	actor, err := resolvePublicActor(ctx, c.UserAuthRepo, c.JwtSecret, req.AnonUserID, req.AnonToken, true)
	if err != nil {
		return err
	}
	if err := ensureAnonUserForCollection(ctx.Request.Context(), c.AnonUsersRepo, collectionID, actor); err != nil {
		return err
	}
	updateReq := socialcontroller.UpdateCommentRequest{
		Actor:     actor,
		CommentID: commentID,
		Cipher:    req.Cipher,
		Nonce:     req.Nonce,
	}
	return c.CommentCtrl.UpdatePayload(ctx, updateReq)
}

func (c *CommentsController) DeleteComment(ctx *gin.Context, collectionID int64, commentID string, req CommentDeleteRequest) error {
	actor, err := resolvePublicActor(ctx, c.UserAuthRepo, c.JwtSecret, req.AnonUserID, req.AnonToken, true)
	if err != nil {
		return err
	}
	if err := ensureAnonUserForCollection(ctx.Request.Context(), c.AnonUsersRepo, collectionID, actor); err != nil {
		return err
	}
	deleteReq := socialcontroller.DeleteCommentRequest{
		Actor:         actor,
		CommentID:     commentID,
		RequireAccess: false,
	}
	return c.CommentCtrl.Delete(ctx, deleteReq)
}

func (c *CommentsController) ListComments(ctx *gin.Context, collectionID int64, since int64, limit int, fileID *int64) ([]socialentity.Comment, bool, error) {
	diffReq := socialcontroller.CommentDiffRequest{
		Actor:         socialcontroller.Actor{},
		CollectionID:  collectionID,
		Since:         since,
		Limit:         limit,
		FileID:        fileID,
		RequireAccess: false,
	}
	return c.CommentCtrl.Diff(ctx, diffReq)
}

func (c *CommentsController) Participants(ctx context.Context, collectionID int64) ([]participant, error) {
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

func (c *CommentsController) ListAnonProfiles(ctx *gin.Context, collectionID int64) ([]socialentity.AnonUser, error) {
	return c.AnonUsersRepo.ListByCollection(ctx.Request.Context(), collectionID)
}
