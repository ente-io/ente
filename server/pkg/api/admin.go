package api

import (
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/ente-io/museum/pkg/controller/emergency"
	"github.com/ente-io/museum/pkg/controller/remotestore"
	"github.com/ente-io/museum/pkg/repo/authenticator"

	"github.com/ente-io/museum/pkg/controller/family"

	bonusEntity "github.com/ente-io/museum/ente/storagebonus"
	"github.com/ente-io/museum/pkg/repo/storagebonus"

	gTime "time"

	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/controller/discord"
	storagebonusCtrl "github.com/ente-io/museum/pkg/controller/storagebonus"
	"github.com/ente-io/museum/pkg/controller/user"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/gin-contrib/requestid"
	"github.com/sirupsen/logrus"

	"github.com/ente-io/museum/pkg/utils/crypto"
	"github.com/ente-io/stacktrace"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/repo"
	emailUtil "github.com/ente-io/museum/pkg/utils/email"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/gin-gonic/gin"
)

// AdminHandler exposes request handlers for all admin related requests
type AdminHandler struct {
	QueueRepo               *repo.QueueRepository
	UserRepo                *repo.UserRepository
	CollectionRepo          *repo.CollectionRepository
	AuthenticatorRepo       *authenticator.Repository
	UserAuthRepo            *repo.UserAuthRepository
	FileRepo                *repo.FileRepository
	BillingRepo             *repo.BillingRepository
	StorageBonusRepo        *storagebonus.Repository
	BillingController       *controller.BillingController
	UserController          *user.UserController
	EmergencyController     *emergency.Controller
	FamilyController        *family.Controller
	RemoteStoreController   *remotestore.Controller
	ObjectCleanupController *controller.ObjectCleanupController
	MailingListsController  *controller.MailingListsController
	DiscordController       *discord.DiscordController
	HashingKey              []byte
	PasskeyController       *controller.PasskeyController
	StorageBonusCtl         *storagebonusCtrl.Controller
}

// Duration for which an admin's token is considered valid
const AdminTokenValidityInMinutes = 10

func (h *AdminHandler) SendMail(c *gin.Context) {
	var req ente.SendEmailRequest
	err := c.ShouldBindJSON(&req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	err = emailUtil.Send(req.To, req.FromName, req.FromEmail, req.Subject, req.Body, nil)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{})
}

func (h *AdminHandler) SubscribeMail(c *gin.Context) {
	email := c.Query("email")
	err := h.MailingListsController.Subscribe(email)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

func (h *AdminHandler) UnsubscribeMail(c *gin.Context) {
	email := c.Query("email")
	err := h.MailingListsController.Unsubscribe(email)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

func (h *AdminHandler) GetUsers(c *gin.Context) {
	err := h.isFreshAdminToken(c)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	sinceTime, err := strconv.ParseInt(c.Query("sinceTime"), 10, 64)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	users, err := h.UserRepo.GetAll(sinceTime, time.Microseconds())
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{"users": users})
}

func (h *AdminHandler) GetUser(c *gin.Context) {
	e := strings.ToLower(strings.TrimSpace(c.Query("email")))
	if e == "" {
		id, err := strconv.ParseInt(c.Query("id"), 10, 64)
		if err != nil {
			handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, ""))
			return
		}
		user, err := h.UserRepo.GetUserByIDInternal(id)
		if err != nil {
			handler.Error(c, stacktrace.Propagate(err, ""))
			return
		}
		response := gin.H{
			"user": user,
		}
		h.attachSubscription(c, user.ID, response)
		c.JSON(http.StatusOK, response)
		return
	}
	emailHash, err := crypto.GetHash(e, h.HashingKey)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	user, err := h.UserRepo.GetUserByEmailHash(emailHash)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	user.Email = e
	response := gin.H{
		"user": user,
	}
	h.attachSubscription(c, user.ID, response)
	c.JSON(http.StatusOK, response)
}

func (h *AdminHandler) DeleteUser(c *gin.Context) {
	err := h.isFreshAdminToken(c)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	email := c.Query("email")
	email = strings.TrimSpace(email)
	if email == "" {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "email id is missing"))
		return
	}
	emailHash, err := crypto.GetHash(email, h.HashingKey)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	user, err := h.UserRepo.GetUserByEmailHash(emailHash)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	adminID := auth.GetUserID(c.Request.Header)
	logger := logrus.WithFields(logrus.Fields{
		"user_id":    user.ID,
		"admin_id":   adminID,
		"user_email": email,
		"req_id":     requestid.Get(c),
		"req_ctx":    "account_deletion",
	})

	// todo: (neeraj) refactor this part, currently there's a circular dependency between user and emergency controllers
	removeLegacyErr := h.EmergencyController.HandleAccountDeletion(c, user.ID, logger)
	if removeLegacyErr != nil {
		handler.Error(c, stacktrace.Propagate(removeLegacyErr, ""))
		return
	}
	response, err := h.UserController.HandleAccountDeletion(c, user.ID, logger)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) deleting account for %d", adminID, user.ID))
	c.JSON(http.StatusOK, response)
}

func (h *AdminHandler) isFreshAdminToken(c *gin.Context) error {
	token := auth.GetToken(c)
	creationTime, err := h.UserAuthRepo.GetTokenCreationTime(token)
	if err != nil {
		return err
	}
	if (creationTime + time.MicroSecondsInOneMinute*AdminTokenValidityInMinutes) < time.Microseconds() {
		err = ente.NewBadRequestError(&ente.ApiErrorParams{
			Message: "Token is too old",
		})
		return err
	}
	return nil
}

func (h *AdminHandler) DisableTwoFactor(c *gin.Context) {
	err := h.isFreshAdminToken(c)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	var request ente.DisableTwoFactorRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Bad request"))
		return
	}

	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) disabling 2FA for account %d", auth.GetUserID(c.Request.Header), request.UserID))
	logger := logrus.WithFields(logrus.Fields{
		"user_id":  request.UserID,
		"admin_id": auth.GetUserID(c.Request.Header),
		"req_id":   requestid.Get(c),
		"req_ctx":  "disable_2fa",
	})
	logger.Info("Initiate disable 2FA")
	err = h.UserController.DisableTwoFactor(request.UserID)
	if err != nil {
		logger.WithError(err).Error("Failed to disable 2FA")
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	logger.Info("2FA successfully disabled")
	c.JSON(http.StatusOK, gin.H{})
}

func (h *AdminHandler) UpdateReferral(c *gin.Context) {
	var request ente.UpdateReferralCodeRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Bad request %s", err.Error()))
		return
	}
	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) updating referral code for %d to %s", auth.GetUserID(c.Request.Header), request.UserID, request.Code))
	err := h.StorageBonusCtl.UpdateReferralCode(c, request.UserID, request.Code, true)
	if err != nil {
		logrus.WithError(err).Error("Failed to disable 2FA")
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{})
}

// RemovePasskeys is an admin API request to disable passkey 2FA for a user account by removing its passkeys.
// This is used when we get a user request to reset their passkeys 2FA when they might've lost access to their devices or synced stores. We verify their identity out of band.
// BY DEFAULT, IF THE USER HAS TOTP BASED 2FA ENABLED, REMOVING PASSKEYS WILL NOT DISABLE TOTP 2FA.
func (h *AdminHandler) RemovePasskeys(c *gin.Context) {
	var request ente.AdminOpsForUserRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Bad request"))
		return
	}

	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) removing passkeys for account %d", auth.GetUserID(c.Request.Header), request.UserID))
	logger := logrus.WithFields(logrus.Fields{
		"user_id":  request.UserID,
		"admin_id": auth.GetUserID(c.Request.Header),
		"req_id":   requestid.Get(c),
		"req_ctx":  "remove_passkeys",
	})
	logger.Info("Initiate remove passkeys")
	err := h.PasskeyController.RemovePasskey2FA(request.UserID)
	if err != nil {
		logger.WithError(err).Error("Failed to remove passkeys")
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	logger.Info("Passkeys successfully removed")
	c.JSON(http.StatusOK, gin.H{})
}

func (h *AdminHandler) UpdateEmailMFA(c *gin.Context) {
	var request ente.AdminOpsForUserRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Bad request"))
		return
	}
	if request.EmailMFA == nil {
		handler.Error(c, stacktrace.Propagate(ente.NewBadRequestWithMessage("emailMFA is required"), ""))
		return
	}

	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) updating email mfa (%v) for account %d", auth.GetUserID(c.Request.Header), *request.EmailMFA, request.UserID))
	logger := logrus.WithFields(logrus.Fields{
		"user_id":  request.UserID,
		"admin_id": auth.GetUserID(c.Request.Header),
		"req_id":   requestid.Get(c),
		"req_ctx":  "disable_email_mfa",
	})
	logger.Info("Initiate remove passkeys")
	err := h.UserController.UpdateEmailMFA(c, request.UserID, *request.EmailMFA)
	if err != nil {
		logger.WithError(err).Error("Failed to update email mfa")
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	logger.Info("Email MFA successfully updated")
	c.JSON(http.StatusOK, gin.H{})
}

func (h *AdminHandler) AddOtt(c *gin.Context) {
	var request ente.AdminOttReq
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Bad request"))
		return
	}
	if err := request.Validate(); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.NewBadRequestWithMessage(err.Error()), "Bad request"))
		return
	}

	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) adding custom ott", auth.GetUserID(c.Request.Header)))
	logger := logrus.WithFields(logrus.Fields{
		"user_id":  request.Email,
		"code":     request.Code,
		"admin_id": auth.GetUserID(c.Request.Header),
		"req_id":   requestid.Get(c),
		"req_ctx":  "custom_ott",
	})

	err := h.UserController.AddAdminOtt(request)
	if err != nil {
		logger.WithError(err).Error("Failed to add ott")
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	logger.Info("Success added ott")
	c.JSON(http.StatusOK, gin.H{})
}

func (h *AdminHandler) TerminateSession(c *gin.Context) {
	var request ente.LogoutSessionReq
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Bad request"))
		return
	}
	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) terminating session for user %d", auth.GetUserID(c.Request.Header), request.UserID))
	err := h.UserController.TerminateSession(request.UserID, request.Token)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{})
}

func (h *AdminHandler) UpdateFeatureFlag(c *gin.Context) {
	var request ente.AdminUpdateKeyValueRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Bad request"))
		return
	}
	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) updating flag:%s to val:%v for %d", auth.GetUserID(c.Request.Header), request.Key, request.Value, request.UserID))

	logger := logrus.WithFields(logrus.Fields{
		"user_id":  request.UserID,
		"admin_id": auth.GetUserID(c.Request.Header),
		"req_id":   requestid.Get(c),
		"req_ctx":  "update_feature_flag",
	})
	logger.Info("Start update")
	err := h.RemoteStoreController.AdminInsertOrUpdate(c, request)
	if err != nil {
		logger.WithError(err).Error("Failed to update flag")
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	logger.Info("successfully updated flag")
	c.JSON(http.StatusOK, gin.H{})
}

func (h *AdminHandler) CloseFamily(c *gin.Context) {

	var request ente.AdminOpsForUserRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Bad request"))
		return
	}

	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) closing family for account %d", auth.GetUserID(c.Request.Header), request.UserID))
	logger := logrus.WithFields(logrus.Fields{
		"user_id":  request.UserID,
		"admin_id": auth.GetUserID(c.Request.Header),
		"req_id":   requestid.Get(c),
		"req_ctx":  "close_family",
	})
	logger.Info("Start close family")
	err := h.FamilyController.CloseFamily(c, request.UserID)
	if err != nil {
		logger.WithError(err).Error("Failed to close family")
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	logger.Info("Finished close family")
	c.JSON(http.StatusOK, gin.H{})
}

func (h *AdminHandler) UpdateSubscription(c *gin.Context) {
	var r ente.UpdateSubscriptionRequest
	if err := c.ShouldBindJSON(&r); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Bad request"))
		return
	}
	r.AdminID = auth.GetUserID(c.Request.Header)
	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) updating subscription for user: %d", r.AdminID, r.UserID))
	err := h.BillingController.UpdateSubscription(r)
	if err != nil {
		logrus.WithError(err).Error("Failed to update subscription")
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	logrus.Info("Updated subscription")
	c.JSON(http.StatusOK, gin.H{})
}

func (h *AdminHandler) ChangeEmail(c *gin.Context) {
	var r ente.ChangeEmailRequest
	if err := c.ShouldBindJSON(&r); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Bad request"))
		return
	}
	adminID := auth.GetUserID(c.Request.Header)
	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) updating email for user: %d", adminID, r.UserID))
	err := h.UserController.UpdateEmail(c, r.UserID, r.Email)
	if err != nil {
		logrus.WithError(err).Error("Failed to update email")
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	logrus.Info("Updated email")
	c.JSON(http.StatusOK, gin.H{})
}

func (h *AdminHandler) ReQueueItem(c *gin.Context) {
	var r ente.ReQueueItemRequest
	if err := c.ShouldBindJSON(&r); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Bad request"))
		return
	}
	adminID := auth.GetUserID(c.Request.Header)
	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) requeueing item %d for queue: %s", adminID, r.ID, r.QueueName))
	err := h.QueueRepo.RequeueItem(c, r.QueueName, r.ID)
	if err != nil {
		logrus.WithError(err).Error("Failed to re-queue item")
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{})
}

func (h *AdminHandler) UpdateBonus(c *gin.Context) {
	var r ente.SupportUpdateBonus
	if err := c.ShouldBindJSON(&r); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "Bad request"))
		return
	}
	if err := r.Validate(); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.NewBadRequestWithMessage(err.Error()), "Bad request"))
		return
	}
	adminID := auth.GetUserID(c.Request.Header)
	var storage, validTill int64
	if r.Testing {
		storage = r.StorageInMB * 1024 * 1024
		validTill = gTime.Now().Add(gTime.Duration(r.Minute) * gTime.Minute).UnixMicro()
	} else {
		storage = r.StorageInGB * 1024 * 1024 * 1024
		validTill = gTime.Now().AddDate(r.Year, 0, 0).UnixMicro()
	}
	var err error
	bonusType := bonusEntity.BonusType(r.BonusType)
	switch r.Action {
	case ente.ADD:
		err = h.StorageBonusRepo.InsertAddOnBonus(c, bonusType, r.UserID, validTill, storage)
	case ente.UPDATE:
		err = h.StorageBonusRepo.UpdateAddOnBonus(c, bonusType, r.UserID, validTill, storage)
	case ente.REMOVE:
		_, err = h.StorageBonusRepo.RemoveAddOnBonus(c, bonusType, r.UserID)
	}
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) : User %d %s", adminID, r.UserID, r.UpdateLog()))
	c.JSON(http.StatusOK, gin.H{})
}

func (h *AdminHandler) RecoverAccount(c *gin.Context) {

	var request ente.RecoverAccountRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Bad request"))
		return
	}
	if request.EmailID == "" || !strings.Contains(request.EmailID, "@") {
		handler.Error(c, stacktrace.Propagate(errors.New("invalid email"), "Bad request"))
		return
	}

	go h.DiscordController.NotifyAdminAction(
		fmt.Sprintf("Admin (%d) recovering account for %d", auth.GetUserID(c.Request.Header), request.UserID))
	logger := logrus.WithFields(logrus.Fields{
		"user_id":    request.UserID,
		"admin_id":   auth.GetUserID(c.Request.Header),
		"user_email": request.EmailID,
		"req_id":     requestid.Get(c),
		"req_ctx":    "account_recovery",
	})
	logger.Info("Initiate account recovery")
	err := h.UserController.HandleAccountRecovery(c, request)
	if err != nil {
		logger.WithError(err).Error("Failed to recover account")
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	logger.Info("Account successfully recovered")
	c.JSON(http.StatusOK, gin.H{})
}

func (h *AdminHandler) GetEmailHash(c *gin.Context) {
	e := c.Query("email")
	hash, err := crypto.GetHash(e, h.HashingKey)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{"hash": hash})
}

func (h *AdminHandler) GetEmailsFromHashes(c *gin.Context) {
	var request ente.GetEmailsFromHashesRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	emails, err := h.UserRepo.GetEmailsFromHashes(request.Hashes)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{"emails": emails})
}

func (h *AdminHandler) attachSubscription(ctx *gin.Context, userID int64, response gin.H) {
	subscription, err := h.BillingRepo.GetUserSubscription(userID)
	if err == nil {
		response["subscription"] = subscription
	}
	details, err := h.UserController.GetDetailsV2(ctx, userID, false, ente.Photos)
	if err == nil {
		response["details"] = details
	}
	tokenInfos, err := h.UserAuthRepo.GetUserTokenInfo(userID)
	if err == nil {
		response["tokens"] = tokenInfos
	}
	authEntryCount, err := h.AuthenticatorRepo.GetAuthCodeCount(ctx, userID)
	if err == nil {
		response["authCodes"] = authEntryCount
	}
}

func (h *AdminHandler) ClearOrphanObjects(c *gin.Context) {
	var req ente.ClearOrphanObjectsRequest
	err := c.ShouldBindJSON(&req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, ""))
		return
	}
	if !h.ObjectCleanupController.IsValidClearOrphanObjectsDC(req.DC) {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, "unsupported dc %s", req.DC))
		return
	}
	go h.ObjectCleanupController.ClearOrphanObjects(req.DC, req.Prefix, req.ForceTaskLock)
	c.JSON(http.StatusOK, gin.H{})
}
