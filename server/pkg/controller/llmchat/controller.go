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
	llmChatMaxAttachmentsFree             = 4
	llmChatMaxAttachmentsPaid             = 10
	llmChatMaxAttachmentFree              = int64(25 * 1024 * 1024)  // 25MB
	llmChatMaxAttachmentPaid              = int64(100 * 1024 * 1024) // 100MB
	llmChatMaxAttachmentStorageFree       = int64(1 * 1024 * 1024 * 1024)
	llmChatMaxAttachmentStoragePaid       = int64(10 * 1024 * 1024 * 1024)
	llmChatMaxMessagesFree          int64 = 2000
	llmChatMaxMessagesPaid          int64 = 50000

	llmChatDiffTypeSessions          = "sessions"
	llmChatDiffTypeMessages          = "messages"
	llmChatDiffTypeSessionTombstones = "session_tombstones"
	llmChatDiffTypeMessageTombstones = "message_tombstones"
)

type Controller struct {
	Repo                *llmchat.Repository
	KeyCache            *cache.Cache
	SubscriptionChecker SubscriptionChecker
	AttachmentCtrl      *AttachmentController
	AttachmentsEnabled  bool
	CleanupAttachments  bool
	UserRepo            InternalUserRepo
	RemoteStoreRepo     RemoteStoreRepo
}

func (c *Controller) attachmentsAllowed(ctx *gin.Context, userID int64) bool {
	if !c.AttachmentsEnabled {
		return false
	}
	return isInternalUser(ctx.Request.Context(), userID, c.UserRepo, c.RemoteStoreRepo)
}

func (c *Controller) CreateKey(ctx *gin.Context, req model.CreateKeyRequest) (*model.Key, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	res, err := c.Repo.CreateKey(ctx, userID, req)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to create llmchat key")
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
	clientID, err := llmchat.ParseClientID(req.ClientMetadata)
	if err != nil {
		return nil, err
	}
	if err := c.Repo.RepairZeroUUIDs(ctx, userID); err != nil {
		return nil, stacktrace.Propagate(err, "failed to repair zero-uuid llmchat records")
	}
	if existingSessionUUID, err := c.Repo.GetSessionUUIDByClientID(ctx, userID, clientID); err != nil {
		return nil, err
	} else if existingSessionUUID != "" {
		req.SessionUUID = existingSessionUUID
	} else if req.SessionUUID == "" || req.SessionUUID == model.ZeroUUID {
		req.SessionUUID = uuid.NewString()
	}
	if _, err := uuid.Parse(req.SessionUUID); err != nil {
		return nil, stacktrace.Propagate(ente.ErrBadRequest, "invalid sessionUUID")
	}
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
	clientID, err := llmchat.ParseClientID(req.ClientMetadata)
	if err != nil {
		return nil, err
	}
	if err := c.Repo.RepairZeroUUIDs(ctx, userID); err != nil {
		return nil, stacktrace.Propagate(err, "failed to repair zero-uuid llmchat records")
	}
	if existingMessageUUID, err := c.Repo.GetMessageUUIDByClientID(ctx, userID, clientID); err != nil {
		return nil, err
	} else if existingMessageUUID != "" {
		req.MessageUUID = existingMessageUUID
	} else if req.MessageUUID == "" || req.MessageUUID == model.ZeroUUID {
		req.MessageUUID = uuid.NewString()
	}
	if _, err := uuid.Parse(req.MessageUUID); err != nil {
		return nil, stacktrace.Propagate(ente.ErrBadRequest, "invalid messageUUID")
	}
	if _, err := uuid.Parse(req.SessionUUID); err != nil {
		return nil, stacktrace.Propagate(ente.ErrBadRequest, "invalid sessionUUID")
	}
	if err := c.ensureSessionActive(ctx, userID, req.SessionUUID); err != nil {
		return nil, err
	}
	if req.ParentMessageUUID != nil {
		if *req.ParentMessageUUID == "" || *req.ParentMessageUUID == model.ZeroUUID {
			req.ParentMessageUUID = nil
		} else if _, err := uuid.Parse(*req.ParentMessageUUID); err != nil {
			return nil, stacktrace.Propagate(ente.ErrBadRequest, "invalid parentMessageUUID")
		}
	}
	if req.Sender != "self" && req.Sender != "other" {
		return nil, stacktrace.Propagate(ente.ErrBadRequest, "invalid sender")
	}

	allowedAttachments := c.attachmentsAllowed(ctx, userID)
	if err := c.validateAttachments(ctx, userID, req.Attachments); err != nil {
		return nil, err
	}
	if !allowedAttachments {
		req.Attachments = nil
	}
	if err := c.enforceMessageLimit(ctx, userID, req.MessageUUID); err != nil {
		return nil, err
	}
	if err := c.enforceAttachmentStorageLimit(ctx, userID, req.MessageUUID, req.Attachments); err != nil {
		return nil, err
	}
	if allowedAttachments && c.AttachmentCtrl != nil {
		for _, attachment := range req.Attachments {
			if err := c.AttachmentCtrl.VerifyUploaded(ctx, userID, attachment.ID, attachment.Size); err != nil {
				return nil, err
			}
		}
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
	if _, err := uuid.Parse(sessionUUID); err != nil {
		return nil, stacktrace.Propagate(ente.ErrBadRequest, "invalid sessionUUID")
	}
	userID := auth.GetUserID(ctx.Request.Header)

	var attachments []model.AttachmentMeta
	if c.CleanupAttachments && c.AttachmentCtrl != nil {
		var err error
		attachments, err = c.Repo.GetActiveSessionMessageAttachments(ctx, userID, sessionUUID)
		if err != nil {
			return nil, stacktrace.Propagate(err, "failed to fetch llmchat session messages")
		}
	}
	_, err := c.Repo.SoftDeleteMessagesForSession(ctx, userID, sessionUUID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to delete llmchat session messages")
	}

	res, err := c.Repo.DeleteSession(ctx, userID, sessionUUID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to delete llmchat session")
	}

	if c.CleanupAttachments && c.AttachmentCtrl != nil {
		for _, attachment := range attachments {
			referenced, refErr := c.Repo.HasActiveAttachmentReference(ctx, userID, attachment.ID)
			if refErr != nil {
				logrus.WithError(refErr).WithField("user_id", userID).Warn("Failed to check llmchat attachment reference")
				continue
			}
			if referenced {
				continue
			}
			if delErr := c.AttachmentCtrl.Delete(ctx.Request.Context(), userID, attachment.ID); delErr != nil {
				logrus.WithError(delErr).WithField("user_id", userID).WithField("attachment_id", attachment.ID).Warn("Failed to delete llmchat attachment")
				continue
			}
			if cleanupErr := c.Repo.DeleteAttachmentRecords(ctx, userID, attachment.ID); cleanupErr != nil {
				logrus.WithError(cleanupErr).WithField("user_id", userID).WithField("attachment_id", attachment.ID).Warn("Failed to delete llmchat attachment records")
			}
		}
	}

	return &res, nil
}

func (c *Controller) DeleteMessage(ctx *gin.Context, messageUUID string) (*model.MessageTombstone, error) {
	if err := c.validateKey(ctx); err != nil {
		return nil, stacktrace.Propagate(err, "failed to validateKey")
	}
	if _, err := uuid.Parse(messageUUID); err != nil {
		return nil, stacktrace.Propagate(ente.ErrBadRequest, "invalid messageUUID")
	}
	userID := auth.GetUserID(ctx.Request.Header)

	var meta llmchat.MessageMeta
	var attachments []model.AttachmentMeta
	if c.CleanupAttachments && c.AttachmentCtrl != nil {
		var err error
		meta, err = c.Repo.GetMessageMeta(ctx, userID, messageUUID)
		if err != nil {
			return nil, stacktrace.Propagate(err, "failed to fetch llmchat message")
		}
		if !meta.IsDeleted {
			attachments, err = c.Repo.GetMessageAttachments(ctx, userID, messageUUID)
			if err != nil {
				return nil, stacktrace.Propagate(err, "failed to fetch llmchat message attachments")
			}
		}
	}

	res, err := c.Repo.DeleteMessage(ctx, userID, messageUUID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to delete llmchat message")
	}

	if c.CleanupAttachments && !meta.IsDeleted && c.AttachmentCtrl != nil {
		for _, attachment := range attachments {
			referenced, refErr := c.Repo.HasActiveAttachmentReference(ctx, userID, attachment.ID)
			if refErr != nil {
				logrus.WithError(refErr).WithField("user_id", userID).Warn("Failed to check llmchat attachment reference")
				continue
			}
			if referenced {
				continue
			}
			if delErr := c.AttachmentCtrl.Delete(ctx.Request.Context(), userID, attachment.ID); delErr != nil {
				logrus.WithError(delErr).WithField("user_id", userID).WithField("attachment_id", attachment.ID).Warn("Failed to delete llmchat attachment")
				continue
			}
			if cleanupErr := c.Repo.DeleteAttachmentRecords(ctx, userID, attachment.ID); cleanupErr != nil {
				logrus.WithError(cleanupErr).WithField("user_id", userID).WithField("attachment_id", attachment.ID).Warn("Failed to delete llmchat attachment records")
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
	if req.BaseSinceTime != nil && *req.BaseSinceTime > 0 {
		baseSinceTime = *req.BaseSinceTime
	}
	maxTime := baseSinceTime
	if req.MaxTime != nil && *req.MaxTime > 0 {
		maxTime = *req.MaxTime
	}
	if maxTime < baseSinceTime {
		maxTime = baseSinceTime
	}

	sinceType := llmChatDiffTypeSessions
	if req.SinceType != nil && *req.SinceType != "" {
		sinceType = *req.SinceType
	}
	if !isValidDiffType(sinceType) {
		return nil, stacktrace.Propagate(ente.ErrBadRequest, "invalid sinceType")
	}

	sinceID := model.ZeroUUID
	if req.SinceID != nil && *req.SinceID != "" {
		sinceID = *req.SinceID
	}
	if _, err := uuid.Parse(sinceID); err != nil {
		sinceID = model.ZeroUUID
	}

	remaining := int(req.Limit)
	sessions := make([]model.SessionDiffEntry, 0)
	messages := make([]model.MessageDiffEntry, 0)
	sessionTombstones := make([]model.SessionTombstone, 0)
	messageTombstones := make([]model.MessageTombstone, 0)

	cursor := model.DiffCursor{
		BaseSinceTime: baseSinceTime,
		SinceTime:     *req.SinceTime,
		MaxTime:       maxTime,
		SinceType:     sinceType,
		SinceID:       sinceID,
	}

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
				if last.UpdatedAt > cursor.MaxTime {
					cursor.MaxTime = last.UpdatedAt
				}
				remaining -= len(entries)
				if hasMore {
					cursor.SinceTime = last.UpdatedAt
					cursor.SinceID = last.SessionUUID
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
				if remaining == 0 {
					cursor.SinceTime = baseSinceTime
					cursor.SinceType = llmChatDiffTypeMessages
					cursor.SinceID = model.ZeroUUID
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
			}
			cursor.SinceTime = baseSinceTime
			cursor.SinceType = llmChatDiffTypeMessages
			cursor.SinceID = model.ZeroUUID

		case llmChatDiffTypeMessages:
			entries, hasMore, err := c.Repo.GetMessageDiffPage(ctx, userID, cursor.SinceTime, cursor.SinceID, int16(remaining))
			if err != nil {
				return nil, stacktrace.Propagate(err, "failed to fetch llmchat message diff")
			}
			messages = append(messages, entries...)
			if len(entries) > 0 {
				last := entries[len(entries)-1]
				if last.UpdatedAt > cursor.MaxTime {
					cursor.MaxTime = last.UpdatedAt
				}
				remaining -= len(entries)
				if hasMore {
					cursor.SinceTime = last.UpdatedAt
					cursor.SinceID = last.MessageUUID
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
				if remaining == 0 {
					cursor.SinceTime = baseSinceTime
					cursor.SinceType = llmChatDiffTypeSessionTombstones
					cursor.SinceID = model.ZeroUUID
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
			}
			cursor.SinceTime = baseSinceTime
			cursor.SinceType = llmChatDiffTypeSessionTombstones
			cursor.SinceID = model.ZeroUUID

		case llmChatDiffTypeSessionTombstones:
			entries, hasMore, err := c.Repo.GetSessionTombstonesPage(ctx, userID, cursor.SinceTime, cursor.SinceID, int16(remaining))
			if err != nil {
				return nil, stacktrace.Propagate(err, "failed to fetch llmchat session tombstones")
			}
			sessionTombstones = append(sessionTombstones, entries...)
			if len(entries) > 0 {
				last := entries[len(entries)-1]
				if last.DeletedAt > cursor.MaxTime {
					cursor.MaxTime = last.DeletedAt
				}
				remaining -= len(entries)
				if hasMore {
					cursor.SinceTime = last.DeletedAt
					cursor.SinceID = last.SessionUUID
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
				if remaining == 0 {
					cursor.SinceTime = baseSinceTime
					cursor.SinceType = llmChatDiffTypeMessageTombstones
					cursor.SinceID = model.ZeroUUID
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
			}
			cursor.SinceTime = baseSinceTime
			cursor.SinceType = llmChatDiffTypeMessageTombstones
			cursor.SinceID = model.ZeroUUID

		case llmChatDiffTypeMessageTombstones:
			entries, hasMore, err := c.Repo.GetMessageTombstonesPage(ctx, userID, cursor.SinceTime, cursor.SinceID, int16(remaining))
			if err != nil {
				return nil, stacktrace.Propagate(err, "failed to fetch llmchat message tombstones")
			}
			messageTombstones = append(messageTombstones, entries...)
			if len(entries) > 0 {
				last := entries[len(entries)-1]
				if last.DeletedAt > cursor.MaxTime {
					cursor.MaxTime = last.DeletedAt
				}
				remaining -= len(entries)
				if hasMore {
					cursor.SinceTime = last.DeletedAt
					cursor.SinceID = last.MessageUUID
					return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
				}
			}

			nextBase := cursor.MaxTime
			nextCursor := model.DiffCursor{
				BaseSinceTime: nextBase,
				SinceTime:     nextBase,
				MaxTime:       nextBase,
				SinceType:     llmChatDiffTypeSessions,
				SinceID:       model.ZeroUUID,
			}
			return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, nextCursor), nil

		default:
			return nil, stacktrace.Propagate(ente.ErrBadRequest, "invalid sinceType")
		}
	}

	return buildDiffResponse(sessions, messages, sessionTombstones, messageTombstones, cursor), nil
}

func (c *Controller) ValidateKey(ctx *gin.Context) error {
	return c.validateKey(ctx)
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

func (c *Controller) ensureSessionActive(ctx *gin.Context, userID int64, sessionUUID string) error {
	meta, err := c.Repo.GetSessionMeta(ctx, sessionUUID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to fetch llmchat session")
	}
	if meta.UserID != userID {
		return stacktrace.Propagate(ente.ErrPermissionDenied, "llmchat session does not belong to user")
	}
	if meta.IsDeleted {
		return stacktrace.Propagate(&ente.ErrNotFoundError, "llmchat session not found")
	}
	return nil
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
	return isPaidUser(c.SubscriptionChecker, userID)
}

func (c *Controller) maxAttachmentSize(userID int64) int64 {
	return maxAttachmentSizeForUser(c.SubscriptionChecker, userID)
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

func (c *Controller) maxAttachmentStorage(userID int64) int64 {
	return maxAttachmentStorageForUser(c.SubscriptionChecker, userID)
}

func (c *Controller) validateAttachments(ctx *gin.Context, userID int64, attachments []model.AttachmentMeta) error {
	if !c.attachmentsAllowed(ctx, userID) {
		if len(attachments) > 0 {
			return stacktrace.Propagate(ente.ErrNotImplemented, "attachments are disabled")
		}
		return nil
	}
	if c.AttachmentCtrl == nil {
		if len(attachments) > 0 {
			return stacktrace.Propagate(ente.ErrNotImplemented, "attachments not configured")
		}
		return nil
	}
	if len(attachments) > c.maxAttachments(userID) {
		return stacktrace.Propagate(&ente.ErrLlmChatAttachmentLimitReached, "")
	}
	maxSize := c.maxAttachmentSize(userID)
	seen := make(map[string]struct{}, len(attachments))
	seenClientIDs := make(map[string]struct{}, len(attachments))
	for _, attachment := range attachments {
		if attachment.ID == "" {
			return stacktrace.Propagate(ente.ErrBadRequest, "missing attachmentId")
		}
		if _, ok := seen[attachment.ID]; ok {
			return stacktrace.Propagate(ente.ErrBadRequest, "duplicate attachmentId")
		}
		seen[attachment.ID] = struct{}{}
		if _, err := uuid.Parse(attachment.ID); err != nil {
			return stacktrace.Propagate(ente.ErrBadRequest, "invalid attachmentId")
		}
		clientID, err := llmchat.ParseClientID(attachment.ClientMetadata)
		if err != nil {
			return err
		}
		if _, ok := seenClientIDs[clientID]; ok {
			return stacktrace.Propagate(ente.ErrBadRequest, "duplicate attachment clientId")
		}
		seenClientIDs[clientID] = struct{}{}
		if attachment.Size < 0 {
			return stacktrace.Propagate(ente.ErrBadRequest, "invalid attachment size")
		}
		if attachment.Size > maxSize {
			return stacktrace.Propagate(&ente.ErrLlmChatAttachmentLimitReached, "")
		}
	}
	return nil
}

func (c *Controller) enforceAttachmentStorageLimit(ctx *gin.Context, userID int64, messageUUID string, attachments []model.AttachmentMeta) error {
	if !c.attachmentsAllowed(ctx, userID) || len(attachments) == 0 {
		return nil
	}
	maxStorage := c.maxAttachmentStorage(userID)
	if maxStorage <= 0 {
		return nil
	}
	var newSize int64
	for _, attachment := range attachments {
		newSize += attachment.Size
	}
	currentUsage, err := c.Repo.GetActiveAttachmentUsage(ctx, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to fetch llmchat attachment usage")
	}
	existingUsage, err := c.Repo.GetActiveMessageAttachmentUsage(ctx, userID, messageUUID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to fetch llmchat message attachment usage")
	}
	projected := currentUsage - existingUsage + newSize
	if projected > maxStorage {
		return stacktrace.Propagate(&ente.ErrLlmChatAttachmentLimitReached, "")
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
		Timestamp: cursor.MaxTime,
	}
}
