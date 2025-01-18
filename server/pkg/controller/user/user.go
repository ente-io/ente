package user

import (
	"errors"
	"fmt"
	"github.com/ente-io/museum/pkg/repo/two_factor_recovery"
	"strings"

	cache2 "github.com/ente-io/museum/ente/cache"
	"github.com/ente-io/museum/pkg/controller/discord"
	"github.com/ente-io/museum/pkg/controller/usercache"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/controller/family"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/repo/datacleanup"
	"github.com/ente-io/museum/pkg/repo/passkey"
	storageBonusRepo "github.com/ente-io/museum/pkg/repo/storagebonus"
	"github.com/ente-io/museum/pkg/utils/billing"
	"github.com/ente-io/museum/pkg/utils/crypto"
	"github.com/ente-io/museum/pkg/utils/email"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"github.com/patrickmn/go-cache"
	"github.com/sirupsen/logrus"
)

// UserController exposes request handlers for all user related requests
type UserController struct {
	UserRepo               *repo.UserRepository
	TwoFactorRecoveryRepo  *two_factor_recovery.Repository
	UsageRepo              *repo.UsageRepository
	UserAuthRepo           *repo.UserAuthRepository
	TwoFactorRepo          *repo.TwoFactorRepository
	PasskeyRepo            *passkey.Repository
	StorageBonusRepo       *storageBonusRepo.Repository
	FileRepo               *repo.FileRepository
	CollectionRepo         *repo.CollectionRepository
	DataCleanupRepo        *datacleanup.Repository
	CollectionCtrl         *controller.CollectionController
	BillingRepo            *repo.BillingRepository
	BillingController      *controller.BillingController
	FamilyController       *family.Controller
	DiscordController      *discord.DiscordController
	MailingListsController *controller.MailingListsController
	PushController         *controller.PushController
	HashingKey             []byte
	SecretEncryptionKey    []byte
	JwtSecret              []byte
	Cache                  *cache.Cache // refers to the auth token cache
	HardCodedOTT           HardCodedOTT
	UserCache              *cache2.UserCache
	UserCacheController    *usercache.Controller
}

const (
	// OTTValidityDurationInMicroSeconds is the duration for which an OTT is valid
	// (60 minutes)
	OTTValidityDurationInMicroSeconds = 60 * 60 * 1000000

	// OTTWrongAttemptLimit is the max number of wrong attempt to verify OTT (to prevent bruteforce guessing)
	// When client hits this limit, they will need to trigger new OTT.
	OTTWrongAttemptLimit = 20

	// OTTActiveCodeLimit is the max number of active OTT a user can have in
	// a time window of OTTValidityDurationInMicroSeconds duration
	OTTActiveCodeLimit = 10

	// TwoFactorValidityDurationInMicroSeconds is the duration for which an OTT is valid
	// (10 minutes)
	TwoFactorValidityDurationInMicroSeconds = 10 * 60 * 1000000

	// TokenLength is the length of the token issued to a verified user
	TokenLength = 32

	// TwoFactorSessionIDLength is the length of the twoFactorSessionID issued to a verified user
	TwoFactorSessionIDLength = 32

	// PassKeySessionIDLength is the length of the passKey sessionID issued to a verified user
	PassKeySessionIDLength = 32

	CryptoPwhashMemLimitInteractive = 67108864
	CryptoPwhashOpsLimitInteractive = 2

	TOTPIssuerORG = "ente"

	// Template and subject for the mail that we send when the user deletes
	// their account.
	AccountDeletedEmailTemplate                       = "account_deleted.html"
	AccountDeletedWithActiveSubscriptionEmailTemplate = "account_deleted_active_sub.html"
	AccountDeletedEmailSubject                        = "Your Ente account has been deleted"
)

func NewUserController(
	userRepo *repo.UserRepository,
	usageRepo *repo.UsageRepository,
	userAuthRepo *repo.UserAuthRepository,
	twoFactorRepo *repo.TwoFactorRepository,
	twoFactorRecoveryRepo *two_factor_recovery.Repository,
	passkeyRepo *passkey.Repository,
	storageBonusRepo *storageBonusRepo.Repository,
	fileRepo *repo.FileRepository,
	collectionController *controller.CollectionController,
	collectionRepo *repo.CollectionRepository,
	dataCleanupRepository *datacleanup.Repository,
	billingRepo *repo.BillingRepository,
	secretEncryptionKeyBytes []byte,
	hashingKeyBytes []byte,
	authCache *cache.Cache,
	jwtSecretBytes []byte,
	billingController *controller.BillingController,
	familyController *family.Controller,
	discordController *discord.DiscordController,
	mailingListsController *controller.MailingListsController,
	pushController *controller.PushController,
	userCache *cache2.UserCache,
	userCacheController *usercache.Controller,
) *UserController {
	return &UserController{
		UserRepo:               userRepo,
		UsageRepo:              usageRepo,
		TwoFactorRecoveryRepo:  twoFactorRecoveryRepo,
		UserAuthRepo:           userAuthRepo,
		StorageBonusRepo:       storageBonusRepo,
		TwoFactorRepo:          twoFactorRepo,
		PasskeyRepo:            passkeyRepo,
		FileRepo:               fileRepo,
		CollectionCtrl:         collectionController,
		CollectionRepo:         collectionRepo,
		DataCleanupRepo:        dataCleanupRepository,
		BillingRepo:            billingRepo,
		SecretEncryptionKey:    secretEncryptionKeyBytes,
		HashingKey:             hashingKeyBytes,
		Cache:                  authCache,
		JwtSecret:              jwtSecretBytes,
		BillingController:      billingController,
		FamilyController:       familyController,
		DiscordController:      discordController,
		MailingListsController: mailingListsController,
		PushController:         pushController,
		HardCodedOTT:           ReadHardCodedOTTFromConfig(),
		UserCache:              userCache,
		UserCacheController:    userCacheController,
	}
}

// GetAttributes returns the key attributes for a user
func (c *UserController) GetAttributes(userID int64) (ente.KeyAttributes, error) {
	return c.UserRepo.GetKeyAttributes(userID)
}

// SetAttributes sets the attributes for a user. The request will fail if key attributes are already set
func (c *UserController) SetAttributes(userID int64, request ente.SetUserAttributesRequest) error {
	_, err := c.UserRepo.GetKeyAttributes(userID)
	if err == nil { // If there are key attributes already set
		return stacktrace.Propagate(ente.ErrPermissionDenied, "key attributes are already set")
	}
	if request.KeyAttributes.MemLimit <= 0 || request.KeyAttributes.OpsLimit <= 0 {
		// note for curious soul in the future
		_ = fmt.Sprintf("Older clients were not passing these values, so server used %d & %d as ops and memLimit",
			CryptoPwhashOpsLimitInteractive, CryptoPwhashMemLimitInteractive)
		return stacktrace.Propagate(ente.ErrBadRequest, "mem or ops limit should be > 0")
	}
	err = c.UserRepo.SetKeyAttributes(userID, request.KeyAttributes)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

// UpdateEmailMFA updates the email MFA for a user.
func (c *UserController) UpdateEmailMFA(context *gin.Context, userID int64, isEnabled bool) error {
	if !isEnabled {
		isSrpSetupDone, err := c.UserAuthRepo.IsSRPSetupDone(context, userID)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		// if SRP is not setup, then we can not disable email MFA
		if !isSrpSetupDone {
			return stacktrace.Propagate(ente.NewConflictError("SRP setup incomplete"), "can not disable email MFA before SRP is setup")
		}
	}
	return c.UserAuthRepo.UpdateEmailMFA(context, userID, isEnabled)
}

// SetRecoveryKey sets the recovery key attributes for a user, if not already set
func (c *UserController) SetRecoveryKey(userID int64, request ente.SetRecoveryKeyRequest) error {
	keyAttr, keyErr := c.UserRepo.GetKeyAttributes(userID)
	if keyErr != nil {
		return stacktrace.Propagate(keyErr, "User keys setup is not completed")
	}
	if keyAttr.RecoveryKeyEncryptedWithMasterKey != "" {
		return stacktrace.Propagate(errors.New("recovery key is already set"), "")
	}
	err := c.UserRepo.SetRecoveryKeyAttributes(userID, request)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

// GetPublicKey returns the public key of a user
func (c *UserController) GetPublicKey(email string) (string, error) {
	userID, err := c.UserRepo.GetUserIDWithEmail(email)
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	key, err := c.UserRepo.GetPublicKey(userID)
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	return key, nil
}

// GetTwoFactorStatus returns a user's two factor status
func (c *UserController) GetTwoFactorStatus(userID int64) (bool, error) {
	isTwoFactorEnabled, err := c.UserRepo.IsTwoFactorEnabled(userID)
	if err != nil {
		return false, stacktrace.Propagate(err, "")
	}
	return isTwoFactorEnabled, nil
}

func (c *UserController) HandleAccountDeletion(ctx *gin.Context, userID int64, logger *logrus.Entry) (*ente.DeleteAccountResponse, error) {
	isSubscriptionCancelled, err := c.BillingController.HandleAccountDeletion(ctx, userID, logger)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	err = c.CollectionCtrl.HandleAccountDeletion(ctx, userID, logger)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	err = c.FamilyController.HandleAccountDeletion(ctx, userID, logger)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	logger.Info("remove push tokens for user")
	c.PushController.RemoveTokensForUser(userID)

	logger.Info("remove active tokens for user")
	err = c.UserAuthRepo.RemoveAllTokens(userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	user, err := c.UserRepo.Get(userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	email := user.Email
	// See also: Do not block on mailing list errors
	go func() {
		_ = c.MailingListsController.Unsubscribe(email)
	}()

	logger.Info("mark user as deleted")
	err = c.UserRepo.Delete(userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	logger.Info("schedule data deletion")
	err = c.DataCleanupRepo.Insert(ctx, userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	go c.NotifyAccountDeletion(email, isSubscriptionCancelled)

	return &ente.DeleteAccountResponse{
		IsSubscriptionCancelled: isSubscriptionCancelled,
		UserID:                  userID,
	}, nil

}

func (c *UserController) NotifyAccountDeletion(userEmail string, isSubscriptionCancelled bool) {
	template := AccountDeletedEmailTemplate
	if !isSubscriptionCancelled {
		template = AccountDeletedWithActiveSubscriptionEmailTemplate
	}
	err := email.SendTemplatedEmail([]string{userEmail}, "ente", "team@ente.io",
		AccountDeletedEmailSubject, template, nil, nil)
	if err != nil {
		logrus.WithError(err).Errorf("Failed to send the account deletion email to %s", userEmail)
	}
}

func (c *UserController) HandleAccountRecovery(ctx *gin.Context, req ente.RecoverAccountRequest) error {
	_, err := c.UserRepo.Get(req.UserID)
	if err == nil {
		return stacktrace.Propagate(ente.NewBadRequestError(&ente.ApiErrorParams{
			Message: "User ID is linked to undeleted account",
		}), "")
	}
	if !errors.Is(err, ente.ErrUserDeleted) {
		return stacktrace.Propagate(err, "error while getting the user")
	}
	// check if the user keyAttributes are still available
	if _, keyErr := c.UserRepo.GetKeyAttributes(req.UserID); keyErr != nil {
		return stacktrace.Propagate(keyErr, "keyAttributes missing? Account can not be recovered")
	}
	email := strings.ToLower(req.EmailID)
	encryptedEmail, err := crypto.Encrypt(email, c.SecretEncryptionKey)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	emailHash, err := crypto.GetHash(email, c.HashingKey)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	err = c.UserRepo.UpdateEmail(req.UserID, encryptedEmail, emailHash)
	if err != nil {
		return stacktrace.Propagate(err, "failed to update email")
	}
	err = c.DataCleanupRepo.RemoveScheduledDelete(ctx, req.UserID)
	if err != nil {
		logrus.WithError(err).Error("failed to remove scheduled delete")
		return stacktrace.Propagate(err, "")
	}
	return stacktrace.Propagate(err, "")
}

func (c *UserController) attachFreeSubscription(userID int64) (ente.Subscription, error) {
	subscription := billing.GetFreeSubscription(userID)
	generatedID, err := c.BillingRepo.AddSubscription(subscription)
	if err != nil {
		return subscription, stacktrace.Propagate(err, "")
	}
	subscription.ID = generatedID
	return subscription, nil
}

func (c *UserController) createUser(email string, source *string) (int64, ente.Subscription, error) {
	encryptedEmail, err := crypto.Encrypt(email, c.SecretEncryptionKey)
	if err != nil {
		return -1, ente.Subscription{}, stacktrace.Propagate(err, "")
	}
	emailHash, err := crypto.GetHash(email, c.HashingKey)
	if err != nil {
		return -1, ente.Subscription{}, stacktrace.Propagate(err, "")
	}
	userID, err := c.UserRepo.Create(encryptedEmail, emailHash, source)
	if err != nil {
		return -1, ente.Subscription{}, stacktrace.Propagate(err, "")
	}
	err = c.UsageRepo.Create(userID)
	if err != nil {
		return -1, ente.Subscription{}, stacktrace.Propagate(err, "failed to add entry in usage")
	}
	subscription, err := c.attachFreeSubscription(userID)
	if err != nil {
		return -1, ente.Subscription{}, stacktrace.Propagate(err, "")
	}
	// Do not block on mailing list errors
	//
	// The mailing lists are hosted on a third party (Zoho), so we do not wish
	// to fail user creation in case Zoho is having temporary issues. So we
	// perform these actions async, and ignore errors that happen with them (a
	// notification will be sent to Discord for those).
	go func() {
		_ = c.MailingListsController.Subscribe(email)
	}()
	return userID, subscription, nil
}
