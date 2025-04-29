package controller

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"

	firebase "firebase.google.com/go"
	"firebase.google.com/go/messaging"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/config"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	log "github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	"google.golang.org/api/option"
)

// PushController controls all push related operations
type PushController struct {
	PushRepo       *repo.PushTokenRepository
	TaskLockRepo   *repo.TaskLockRepository
	HostName       string
	FirebaseClient *messaging.Client
}

type PushToken struct {
	UserID         int64
	FCMToken       *string
	APNSToken      *string
	CreatedAt      int64
	UpdatedAt      int64
	LastNotifiedAt int64
}

// Interval before which the last push was sent
const pushIntervalInMinutes = 60

// Limit defined by FirebaseClient.SendAll(...)
const concurrentPushesInOneShot = 500

const taskLockName = "fcm-push-lock"

const taskLockDurationInMinutes = 5

// As proposed by https://firebase.google.com/docs/cloud-messaging/manage-tokens#ensuring-registration-token-freshness
const tokenExpiryDurationInDays = 61

func NewPushController(pushRepo *repo.PushTokenRepository, taskLockRepo *repo.TaskLockRepository, hostName string) *PushController {
	client, err := newFirebaseClient()
	if err != nil {
		log.Error(fmt.Errorf("error creating Firebase client: %v", err))
	}
	return &PushController{PushRepo: pushRepo, TaskLockRepo: taskLockRepo, HostName: hostName, FirebaseClient: client}
}

func newFirebaseClient() (*messaging.Client, error) {
	firebaseCredentialsFile, err := config.CredentialFilePath("fcm-service-account.json")
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if firebaseCredentialsFile == "" {
		// Can happen when running locally
		return nil, nil
	}

	opt := option.WithCredentialsFile(firebaseCredentialsFile)
	app, err := firebase.NewApp(context.Background(), nil, opt)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	client, err := app.Messaging(context.Background())
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	return client, nil
}

func (c *PushController) AddToken(userID int64, token ente.PushTokenRequest) error {
	return stacktrace.Propagate(c.PushRepo.AddToken(userID, token), "")
}

func (c *PushController) RemoveTokensForUser(userID int64) error {
	return stacktrace.Propagate(c.PushRepo.RemoveTokensForUser(userID), "")
}

func (c *PushController) SendPushes() {
	lockStatus, err := c.TaskLockRepo.AcquireLock(taskLockName,
		time.MicrosecondsAfterMinutes(taskLockDurationInMinutes), c.HostName)
	if err != nil {
		log.Error("Unable to acquire lock to send pushes", err)
		return
	}
	if !lockStatus {
		log.Info("Skipping sending pushes since there is an existing lock to send pushes")
		return
	}
	defer c.releaseTaskLock()

	tokens, err := c.PushRepo.GetTokensToBeNotified(time.MicrosecondsBeforeMinutes(pushIntervalInMinutes),
		concurrentPushesInOneShot)
	if err != nil {
		log.Error(fmt.Errorf("error fetching tokens to be notified: %v", err))
		return
	}

	err = c.sendFCMPushes(tokens, map[string]string{"action": "sync"})
	if err != nil {
		log.Error(fmt.Errorf("error sending pushes: %v", err))
		return
	}

	c.updateLastNotificationTime(tokens)
}

func (c *PushController) ClearExpiredTokens() {
	err := c.PushRepo.RemoveTokensOlderThan(time.NDaysFromNow(-1 * tokenExpiryDurationInDays))
	if err != nil {
		log.Errorf("Error while removing older tokens %s", err)
	} else {
		log.Info("Cleared expired FCM tokens")
	}
}

func (c *PushController) releaseTaskLock() {
	err := c.TaskLockRepo.ReleaseLock(taskLockName)
	if err != nil {
		log.Errorf("Error while releasing lock %s", err)
	}
}

func (c *PushController) updateLastNotificationTime(pushTokens []ente.PushToken) {
	err := c.PushRepo.SetLastNotificationTimeToNow(pushTokens)
	if err != nil {
		log.Error(fmt.Errorf("error updating last notified at times: %v", err))
	}
}

func (c *PushController) sendFCMPushes(pushTokens []ente.PushToken, payload map[string]string) error {
	firebaseClient := c.FirebaseClient
	silent := viper.GetBool("internal.silent")
	if silent || firebaseClient == nil {
		if len(pushTokens) > 0 {
			log.Info("Skipping sending pushes to " + strconv.Itoa(len(pushTokens)) + " devices")
		}
		return nil
	}

	log.Info("Sending pushes to " + strconv.Itoa(len(pushTokens)) + " devices")
	if len(pushTokens) == 0 {
		return nil
	}
	if len(pushTokens) > concurrentPushesInOneShot {
		return errors.New("cannot send these many pushes in one shot")
	}
	marshal, _ := json.Marshal(pushTokens)
	log.WithField("devices", string(marshal)).Info("push to following devices")
	fcmTokens := make([]string, 0)
	for _, pushTokenData := range pushTokens {
		fcmTokens = append(fcmTokens, pushTokenData.FCMToken)
	}

	message := &messaging.MulticastMessage{
		Tokens:  fcmTokens,
		Data:    payload,
		Android: &messaging.AndroidConfig{Priority: "high"},
		APNS: &messaging.APNSConfig{
			Headers: map[string]string{
				"apns-push-type": "background",
				"apns-priority":  "5",             // Must be `5` when `contentAvailable` is set to true.
				"apns-topic":     "io.ente.frame", // bundle identifier
			},
			Payload: &messaging.APNSPayload{Aps: &messaging.Aps{ContentAvailable: true}},
		},
	}
	result, err := firebaseClient.SendMulticast(context.Background(), message)
	if err != nil {
		return stacktrace.Propagate(err, "Error sending pushes")
	} else {
		log.Info("Send push result: success count: " + strconv.Itoa(result.SuccessCount) +
			", failure count: " + strconv.Itoa(result.FailureCount))
		return nil
	}
}
