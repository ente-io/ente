package controller

import (
	"context"
	"fmt"
	"strconv"
	"strings"

	"github.com/ente-io/museum/pkg/controller/commonbilling"
	emailCtrl "github.com/ente-io/museum/pkg/controller/email"

	"github.com/prometheus/common/log"

	"github.com/ente-io/stacktrace"
	"github.com/gin-contrib/requestid"
	"github.com/gin-gonic/gin"
	"github.com/sirupsen/logrus"
	"github.com/spf13/viper"

	"github.com/awa/go-iap/appstore"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/array"
)

// AppStoreController provides abstractions for handling billing on AppStore
type AppStoreController struct {
	AppStoreClient          appstore.Client
	BillingRepo             *repo.BillingRepository
	FileRepo                *repo.FileRepository
	UserRepo                *repo.UserRepository
	NotificationHistoryRepo *repo.NotificationHistoryRepository
	BillingPlansPerCountry  ente.BillingPlansPerCountry
	CommonBillCtrl          *commonbilling.Controller
	// appStoreSharedPassword is the password to be used to access AppStore APIs
	appStoreSharedPassword string
}

// Return a new instance of AppStoreController
func NewAppStoreController(
	plans ente.BillingPlansPerCountry,
	billingRepo *repo.BillingRepository,
	fileRepo *repo.FileRepository,
	userRepo *repo.UserRepository,
	notificationHistoryRepo *repo.NotificationHistoryRepository,
	commonBillCtrl *commonbilling.Controller,
) *AppStoreController {
	appleSharedSecret := viper.GetString("apple.shared-secret")
	return &AppStoreController{
		AppStoreClient:          *appstore.New(),
		BillingRepo:             billingRepo,
		FileRepo:                fileRepo,
		UserRepo:                userRepo,
		NotificationHistoryRepo: notificationHistoryRepo,
		BillingPlansPerCountry:  plans,
		appStoreSharedPassword:  appleSharedSecret,
		CommonBillCtrl:          commonBillCtrl,
	}
}

var SubsUpdateNotificationTypes = []string{string(appstore.NotificationTypeDidChangeRenewalStatus), string(appstore.NotificationTypeCancel), string(appstore.NotificationTypeDidRevoke)}

// HandleNotification handles an AppStore notification
func (c *AppStoreController) HandleNotification(ctx *gin.Context, notification appstore.SubscriptionNotification) error {
	logger := logrus.WithFields(logrus.Fields{
		"req_id": requestid.Get(ctx),
	})
	purchase, err := c.verifyAppStoreSubscription(notification.UnifiedReceipt.LatestReceipt)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	latestReceiptInfo := c.getLatestReceiptInfo(purchase.LatestReceiptInfo)
	if latestReceiptInfo.TransactionID == latestReceiptInfo.OriginalTransactionID && !array.StringInList(string(notification.NotificationType), SubsUpdateNotificationTypes) {
		var logMsg = fmt.Sprintf("Ignoring notification of type %s", notification.NotificationType)
		if notification.NotificationType != appstore.NotificationTypeInitialBuy {
			// log unexpected notification types
			logger.Error(logMsg)
		} else {
			logger.Info(logMsg)
		}
		// First subscription, no user to link to
		return nil
	}
	subscription, err := c.BillingRepo.GetSubscriptionForTransaction(latestReceiptInfo.OriginalTransactionID, ente.AppStore)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	expiryTimeInMillis, _ := strconv.ParseInt(latestReceiptInfo.ExpiresDate.ExpiresDateMS, 10, 64)
	if latestReceiptInfo.ProductID == subscription.ProductID && expiryTimeInMillis*1000 < subscription.ExpiryTime {
		// Outdated notification, no-op
	} else {
		if latestReceiptInfo.ProductID != subscription.ProductID {
			var newPlan ente.BillingPlan
			plans := c.BillingPlansPerCountry["EU"] // Country code is irrelevant since Storage will be the same for a given subscriptionID
			for _, plan := range plans {
				if plan.IOSID == latestReceiptInfo.ProductID {
					newPlan = plan
					break
				}
			}
			if newPlan.Storage < subscription.Storage { // Downgrade
				canDowngrade, canDowngradeErr := c.CommonBillCtrl.CanDowngradeToGivenStorage(newPlan.Storage, subscription.UserID)
				if canDowngradeErr != nil {
					return stacktrace.Propagate(canDowngradeErr, "")
				}
				if !canDowngrade {
					return stacktrace.Propagate(ente.ErrCannotDowngrade, "")
				}
				log.Info("Usage is good")
			}
			newSubscription := ente.Subscription{
				Storage:               newPlan.Storage,
				ExpiryTime:            expiryTimeInMillis * 1000,
				ProductID:             latestReceiptInfo.ProductID,
				PaymentProvider:       ente.AppStore,
				OriginalTransactionID: latestReceiptInfo.OriginalTransactionID,
				Attributes:            ente.SubscriptionAttributes{LatestVerificationData: notification.UnifiedReceipt.LatestReceipt},
			}
			err = c.BillingRepo.ReplaceSubscription(
				subscription.ID,
				newSubscription,
			)
			if err != nil {
				return stacktrace.Propagate(err, "")
			}

			c.NotificationHistoryRepo.DeleteLastNotification(subscription.UserID, emailCtrl.StorageLimitExceededTemplateID)
			c.NotificationHistoryRepo.DeleteLastNotification(subscription.UserID, emailCtrl.StorageLimitExceedingTemplateID)

		} else {
			if notification.NotificationType == appstore.NotificationTypeDidChangeRenewalStatus {
				err := c.BillingRepo.UpdateSubscriptionCancellationStatus(subscription.UserID, notification.AutoRenewStatus == "false")
				if err != nil {
					return stacktrace.Propagate(err, "")
				}
			} else if notification.NotificationType == appstore.NotificationTypeCancel || notification.NotificationType == appstore.NotificationTypeDidRevoke {
				err := c.CommonBillCtrl.OnSubscriptionCancelled(subscription.UserID)
				if err != nil {
					return stacktrace.Propagate(err, "")
				}
			}
			err = c.BillingRepo.UpdateSubscriptionExpiryTime(subscription.ID, expiryTimeInMillis*1000)
			if err != nil {
				return stacktrace.Propagate(err, "")
			}
		}
	}
	err = c.BillingRepo.LogAppStorePush(subscription.UserID, notification, *purchase)
	return stacktrace.Propagate(err, "")
}

// GetVerifiedSubscription verifies and returns the verified subscription
func (c *AppStoreController) GetVerifiedSubscription(userID int64, productID string, verificationData string) (ente.Subscription, error) {
	var s ente.Subscription
	s.UserID = userID
	s.ProductID = productID
	s.PaymentProvider = ente.AppStore
	s.Attributes.LatestVerificationData = verificationData
	plans := c.BillingPlansPerCountry["EU"] // Country code is irrelevant since Storage will be the same for a given subscriptionID

	response, err := c.verifyAppStoreSubscription(verificationData)
	if err != nil {
		return ente.Subscription{}, stacktrace.Propagate(err, "")
	}
	for _, plan := range plans {
		if plan.IOSID == productID {
			s.Storage = plan.Storage
			break
		}
	}
	latestReceiptInfo := c.getLatestReceiptInfo(response.LatestReceiptInfo)
	s.OriginalTransactionID = latestReceiptInfo.OriginalTransactionID
	expiryTime, _ := strconv.ParseInt(latestReceiptInfo.ExpiresDate.ExpiresDateMS, 10, 64)
	s.ExpiryTime = expiryTime * 1000
	return s, nil
}

// VerifyAppStoreSubscription verifies an AppStore subscription
func (c *AppStoreController) verifyAppStoreSubscription(verificationData string) (*appstore.IAPResponse, error) {
	iapRequest := appstore.IAPRequest{
		ReceiptData: verificationData,
		Password:    c.appStoreSharedPassword,
	}
	response := &appstore.IAPResponse{}
	context := context.Background()
	err := c.AppStoreClient.Verify(context, iapRequest, response)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if response.Status != 0 {
		return nil, ente.ErrBadRequest
	}
	return response, nil
}

func (c *AppStoreController) getLatestReceiptInfo(receiptInfo []appstore.InApp) appstore.InApp {
	latestReceiptInfo := receiptInfo[0]
	for _, receiptInfo := range receiptInfo {
		if strings.Compare(latestReceiptInfo.ExpiresDate.ExpiresDateMS, receiptInfo.ExpiresDate.ExpiresDateMS) < 0 {
			latestReceiptInfo = receiptInfo
		}
	}
	return latestReceiptInfo
}
