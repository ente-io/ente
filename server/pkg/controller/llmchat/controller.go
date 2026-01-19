package llmchat

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/sirupsen/logrus"

	"github.com/google/uuid"

	"github.com/ente-io/museum/ente"
	model "github.com/ente-io/museum/ente/llmchat"
	"github.com/ente-io/museum/pkg/repo/llmchat"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"github.com/patrickmn/go-cache"
)

type SubscriptionChecker interface {
	HasActiveSelfOrFamilySubscription(userID int64, mustBeOnPaidPlan bool) error
}

const (
	llmChatMaxAttachmentsFree       = 4
	llmChatMaxAttachmentsPaid       = 10
	llmChatMaxAttachmentFree        = int64(25 * 1024 * 1024)  // 25MB
	llmChatMaxAttachmentPaid        = int64(100 * 1024 * 1024) // 100MB
	llmChatMaxMessagesFree    int64 = 2000
	llmChatMaxMessagesPaid    int64 = 50000

	llmChatDiffTypeSessions          = "sessions"
	llmChatDiffTypeMessages          = "messages"
	llmChatDiffTypeSessionTombstones = "session_tombstones"
	llmChatDiffTypeMessageTombstones = "message_tombstones"

	zeroUUID = "00000000-0000-0000-0000-000000000000"
)

// Controller exposes business logic for llmchat.
type Controller struct {
	Repo                *llmchat.Repository
	KeyCache            *cache.Cache
	SubscriptionChecker SubscriptionChecker
	AttachmentCtrl      *AttachmentController
}

func (c *Controller) UpsertKey(ctx *gin.Context, req model.UpsertKeyRequest) (*model.Key, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	res, err := c.Repo.UpsertKey(ctx, userID, req)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to upsert llmchat key")
	}
	c.setKeyCache(userID)
	return &res, nil
}

func (c *Controller) GetKey(ctx *gin.Context) (*model.Key, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	res, err := c.Repo.GetKey(ctx, userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to fetch llmchat key")
	}
	c.setKeyCache(userID)
	return &res, nil
}

func (c *Controller) UpsertSession(ctx *gin.Context, req model.UpsertSessionRequest) (*model.Session, error) {
	if err := c.validateKey(ctx); err != nil {
		return nil, stacktrace.Propagate(err, "failed to validateKey")
	}
	userID := auth.GetUserID(ctx.Request.Header)
	res, err := c.Repo.UpsertSession(ctx, userID, req)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to upsert llmchat session")
	}
	return &res, nil
}

func (c *Controller) UpsertMessage(ctx *gin.Context, req model.UpsertMessageRequest) (*model.Message, error) {
	if err := c.validateKey(ctx); err != nil {
		return nil, stacktrace.Propagate(err, "failed to validateKey")
	}
	userID := auth.GetUserID(ctx.Request.Header)

	if err := c.validateAttachments(userID, req.Attachments); err != nil {
		return nil, err
	}
	if err := c.enforceMessageLimit(ctx, userID, req.MessageUUID); err != nil {
		return nil, err
	}

	res, err := c.Repo.UpsertMessage(ctx, userID, req)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to upsert llmchat message")
	}
	return &res, nil
}

func (c *Controller) DeleteSession(ctx *gin.Context, sessionUUID string) (*model.SessionTombstone, error) {
	if err := c.validateKey(ctx); err != nil {
		return nil, stacktrace.Propagate(err, "failed to validateKey")
	}
	userID := auth.GetUserID(ctx.Request.Header)

	attachments, err := c.Repo.GetActiveSessionMessageAttachments(ctx, userID, sessionUUID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to fetch llmchat session messages")
	}
	_, err = c.Repo.SoftDeleteMessagesForSession(ctx, userID, sessionUUID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to delete llmchat session messages")
	}

	res, err := c.Repo.DeleteSession(ctx, userID, sessionUUID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to delete llmchat session")
	}

	if c.AttachmentCtrl != nil {
		for _, attachment := range attachments {
			if attachment.ID == "" {
				continue
			}
			if _, parseErr := uuid.Parse(attachment.ID); parseErr != nil {
				continue
			}
			referenced, refErr := c.Repo.HasActiveAttachmentReference(ctx, userID, attachment.ID)
			if refErr != nil {
				logrus.WithError(refErr).WithField("user_id", userID).Warn("Failed to check llmchat attachment reference")
				continue
			}
			if referenced {
				continue
			}
			if delErr := c.AttachmentCtrl.Delete(ctx, userID, attachment.ID); delErr != nil {
				logrus.WithError(delErr).WithField("user_id", userID).WithField("attachment_id", attachment.ID).Warn("Failed to delete llmchat attachment")
			}
		}
	}

	return &res, nil
}

func (c *Controller) DeleteMessage(ctx *gin.Context, messageUUID string) (*model.MessageTombstone, error) {
	if err := c.validateKey(ctx); err != nil {
		return nil, stacktrace.Propagate(err, "failed to validateKey")
	}
	userID := auth.GetUserID(ctx.Request.Header)

	meta, err := c.Repo.GetMessageMeta(ctx, userID, messageUUID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to fetch llmchat message")
	}

	res, err := c.Repo.DeleteMessage(ctx, userID, messageUUID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to delete llmchat message")
	}

	if !meta.IsDeleted && c.AttachmentCtrl != nil {
		for _, attachment := range meta.Attachments {
			if attachment.ID == "" {
				continue
			}
			if _, parseErr := uuid.Parse(attachment.ID); parseErr != nil {
				continue
			}
			referenced, refErr := c.Repo.HasActiveAttachmentReference(ctx, userID, attachment.ID)
			if refErr != nil {
				logrus.WithError(refErr).WithField("user_id", userID).Warn("Failed to check llmchat attachment reference")
				continue
			}
			if referenced {
				continue
			}
			if delErr := c.AttachmentCtrl.Delete(ctx, userID, attachment.ID); delErr != nil {
				logrus.WithError(delErr).WithField("user_id", userID).WithField("attachment_id", attachment.ID).Warn("Failed to delete llmchat attachment")
			}
		}
	}

	return &res, nil
}

func (c *Controller) GetDiff(ctx *gin.Context, req model.GetDiffRequest) (*model.GetDiffResponse, error) {
	if err := c.validateKey(ctx); err != nil {
		return nil, stacktrace.Propagate(err, "failed to validateKey")
	}
	userID := auth.GetUserID(ctx.Request.Header)

	baseSinceTime := *req.SinceTime
	sinceType := llmChatDiffTypeSessions
	if req.SinceType != nil && *req.SinceType != "" {
		sinceType = *req.SinceType
	}
	if !isValidDiffType(sinceType) {
		return nil, stacktrace.Propagate(ente.ErrBadRequest, "invalid sinceType")
	}

	sinceID := zeroUUID
	if req.SinceID != nil && *req.SinceID != "" {
		sinceID = *req.SinceID
	}
	if _, err := uuid.Parse(sinceID); err != nil {
		sinceID = zeroUUID
	}

	remaining := int(req.Limit)
	sessions := make([]model.SessionDiffEntry, 0)
	messages := make([]model.MessageDiffEntry, 0)
	sessionTombstones := make([]model.SessionTombstone, 0)
	messageTombstones := make([]model.MessageTombstone, 0)

	maxTimestamp := baseSinceTime
	cursor := model.DiffCursor{SinceTime: baseSinceTime, SinceType: sinceType, SinceID: sinceID}

	for remaining > 0 {
		switch cursor.SinceType {
		case llmChatDiffTypeSessions:
			entries, hasMore, err := c.Repo.GetSessionDiffPage(ctx, userID, cursor.SinceTime, cursor.SinceID, int16(remaining))
			if err != nil {
				return nil, stacktrace.Propagate(err, "failed to fetch llmchat session diff")
			}
			sessions = append(sessions, entries...)
			if len(entries) > 0 {
				last := entries[len(entries)-1]
				if last.UpdatedAt > maxTimestamp {
					maxTimestamp = last.UpdatedAt
				}
				remaining -= len(entries)
				if hasMore {
					cursor.SinceTime = last.UpdatedAt
					cursor.SinceID = last.SessionUUID
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
				if remaining == 0 {
					cursor = model.DiffCursor{SinceTime: baseSinceTime, SinceType: llmChatDiffTypeMessages, SinceID: zeroUUID}
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
			} else {
				// exhausted
			}
			cursor = model.DiffCursor{SinceTime: baseSinceTime, SinceType: llmChatDiffTypeMessages, SinceID: zeroUUID}

		case llmChatDiffTypeMessages:
			entries, hasMore, err := c.Repo.GetMessageDiffPage(ctx, userID, cursor.SinceTime, cursor.SinceID, int16(remaining))
			if err != nil {
				return nil, stacktrace.Propagate(err, "failed to fetch llmchat message diff")
			}
			messages = append(messages, entries...)
			if len(entries) > 0 {
				last := entries[len(entries)-1]
				if last.UpdatedAt > maxTimestamp {
					maxTimestamp = last.UpdatedAt
				}
				remaining -= len(entries)
				if hasMore {
					cursor.SinceTime = last.UpdatedAt
					cursor.SinceID = last.MessageUUID
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
				if remaining == 0 {
					cursor = model.DiffCursor{SinceTime: baseSinceTime, SinceType: llmChatDiffTypeSessionTombstones, SinceID: zeroUUID}
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
			}
			cursor = model.DiffCursor{SinceTime: baseSinceTime, SinceType: llmChatDiffTypeSessionTombstones, SinceID: zeroUUID}

		case llmChatDiffTypeSessionTombstones:
			entries, hasMore, err := c.Repo.GetSessionTombstonesPage(ctx, userID, cursor.SinceTime, cursor.SinceID, int16(remaining))
			if err != nil {
				return nil, stacktrace.Propagate(err, "failed to fetch llmchat session tombstones")
			}
			sessionTombstones = append(sessionTombstones, entries...)
			if len(entries) > 0 {
				last := entries[len(entries)-1]
				if last.DeletedAt > maxTimestamp {
					maxTimestamp = last.DeletedAt
				}
				remaining -= len(entries)
				if hasMore {
					cursor.SinceTime = last.DeletedAt
					cursor.SinceID = last.SessionUUID
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
				if remaining == 0 {
					cursor = model.DiffCursor{SinceTime: baseSinceTime, SinceType: llmChatDiffTypeMessageTombstones, SinceID: zeroUUID}
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
			}
			cursor = model.DiffCursor{SinceTime: baseSinceTime, SinceType: llmChatDiffTypeMessageTombstones, SinceID: zeroUUID}

		case llmChatDiffTypeMessageTombstones:
			entries, hasMore, err := c.Repo.GetMessageTombstonesPage(ctx, userID, cursor.SinceTime, cursor.SinceID, int16(remaining))
			if err != nil {
				return nil, stacktrace.Propagate(err, "failed to fetch llmchat message tombstones")
			}
			messageTombstones = append(messageTombstones, entries...)
			if len(entries) > 0 {
				last := entries[len(entries)-1]
				if last.DeletedAt > maxTimestamp {
					maxTimestamp = last.DeletedAt
				}
				remaining -= len(entries)
				if hasMore {
					cursor.SinceTime = last.DeletedAt
					cursor.SinceID = last.MessageUUID
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
				if remaining == 0 {
					cursor = model.DiffCursor{SinceTime: maxTimestamp, SinceType: llmChatDiffTypeSessions, SinceID: zeroUUID}
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
			}
			cursor = model.DiffCursor{SinceTime: maxTimestamp, SinceType: llmChatDiffTypeSessions, SinceID: zeroUUID}

		default:
			return nil, stacktrace.Propagate(ente.ErrBadRequest, "invalid sinceType")
		}
	}

	return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
}

func (c *Controller) validateKey(ctx *gin.Context) error {
	userID := auth.GetUserID(ctx.Request.Header)
	cacheKey := c.keyCacheKey(userID)
	if c.KeyCache != nil {
		if cached, found := c.KeyCache.Get(cacheKey); found {
			if ok, okType := cached.(bool); okType && ok {
				return nil
			}
		}
	}

	_, err := c.Repo.GetKey(ctx, userID)
	if err != nil && errors.Is(err, &ente.ErrNotFoundError) {
		return stacktrace.Propagate(&ente.ApiError{
			Code:           ente.AuthKeyNotCreated,
			Message:        "Chat key is not created",
			HttpStatusCode: http.StatusBadRequest,
		}, "")
	}
	if err == nil {
		c.setKeyCache(userID)
	}
	return err
}

func (c *Controller) keyCacheKey(userID int64) string {
	return fmt.Sprintf("llmchat_key:%d", userID)
}

func (c *Controller) setKeyCache(userID int64) {
	if c.KeyCache == nil {
		return
	}
	c.KeyCache.SetDefault(c.keyCacheKey(userID), true)
}

func (c *Controller) isPaidUser(userID int64) bool {
	if c.SubscriptionChecker == nil {
		return false
	}
	return c.SubscriptionChecker.HasActiveSelfOrFamilySubscription(userID, false) == nil
}

func (c *Controller) maxAttachmentSize(userID int64) int64 {
	if c.isPaidUser(userID) {
		return llmChatMaxAttachmentPaid
	}
	return llmChatMaxAttachmentFree
}

func (c *Controller) maxAttachments(userID int64) int {
	if c.isPaidUser(userID) {
		return llmChatMaxAttachmentsPaid
	}
	return llmChatMaxAttachmentsFree
}

func (c *Controller) maxMessages(userID int64) int64 {
	if c.isPaidUser(userID) {
		return llmChatMaxMessagesPaid
	}
	return llmChatMaxMessagesFree
}

func (c *Controller) validateAttachments(userID int64, attachments []model.AttachmentMeta) error {
	if attachments == nil {
		attachments = []model.AttachmentMeta{}
	}
	if len(attachments) > c.maxAttachments(userID) {
		return stacktrace.Propagate(&ente.ErrLlmChatAttachmentLimitReached, "")
	}
	maxSize := c.maxAttachmentSize(userID)
	for _, attachment := range attachments {
		if attachment.ID == "" {
			return stacktrace.Propagate(ente.ErrBadRequest, "missing attachment id")
		}
		if _, err := uuid.Parse(attachment.ID); err != nil {
			return stacktrace.Propagate(ente.ErrBadRequest, "invalid attachment id")
		}
		if attachment.Size < 0 {
			return stacktrace.Propagate(ente.ErrBadRequest, "invalid attachment size")
		}
		if attachment.Size > maxSize {
			return stacktrace.Propagate(&ente.ErrLlmChatAttachmentLimitReached, "")
		}
	}
	return nil
}

func (c *Controller) enforceMessageLimit(ctx *gin.Context, userID int64, messageUUID string) error {
	meta, err := c.Repo.GetMessageMeta(ctx, userID, messageUUID)
	if err == nil {
		if !meta.IsDeleted {
			return nil
		}
	} else if !errors.Is(err, &ente.ErrNotFoundError) {
		return stacktrace.Propagate(err, "failed to check llmchat message")
	}

	count, err := c.Repo.GetActiveMessageCount(ctx, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to count llmchat messages")
	}
	if count >= c.maxMessages(userID) {
		return stacktrace.Propagate(&ente.ErrLlmChatMessageLimitReached, "")
	}
	return nil
}

func isValidDiffType(diffType string) bool {
	switch diffType {
	case llmChatDiffTypeSessions,
		llmChatDiffTypeMessages,
		llmChatDiffTypeSessionTombstones,
		llmChatDiffTypeMessageTombstones:
		return true
	default:
		return false
	}
}

func buildDiffResponse(
	sessions []model.SessionDiffEntry,
	messages []model.MessageDiffEntry,
	sessionTombstones []model.SessionTombstone,
	messageTombstones []model.MessageTombstone,
	cursor model.DiffCursor,
) *model.GetDiffResponse {
	return &model.GetDiffResponse{
		Sessions: sessions,
		Messages: messages,
		Tombstones: model.DiffTombstones{
			Sessions: sessionTombstones,
			Messages: messageTombstones,
		},
		Cursor:    cursor,
		Timestamp: cursor.SinceTime,
	}
}
