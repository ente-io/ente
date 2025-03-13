package email

import (
	"fmt"
	"strconv"
	t "time"

	"github.com/avct/uasurfer"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/lock"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/email"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	log "github.com/sirupsen/logrus"
)

const (
	WebAppFirstUploadTemplate    = "web_app_first_upload.html"
	MobileAppFirstUploadTemplate = "mobile_app_first_upload.html"
	FirstUploadEmailSubject      = "Congratulations! 🎉"

	StorageLimitExceededMailLock   = "storage_limit_exceeded_mail_lock"
	StorageLimitExceededTemplateID = "storage_limit_exceeded"
	StorageLimitExceededTemplate   = "storage_limit_exceeded.html"

	FilesCollectedTemplate   = "files_collected.html"
	FilesCollectedTemplateID = "files_collected"
	FilesCollectedSubject    = "You've got photos!"

	SubscriptionUpgradedTemplate = "subscription_upgraded.html"
	SubscriptionUpgradedSubject  = "Thank you for choosing Ente!"

	SubscriptionCancelledSubject        = "Good bye (?) from Ente"
	SubscriptionCancelledTemplate       = "subscription_cancelled.html"
	FilesCollectedMuteDurationInMinutes = 10

	StorageLimitExceededSubject = "[Alert] You have exceeded your storage limit"
	ReferralSuccessfulTemplate  = "successful_referral.html"
	ReferralSuccessfulSubject   = "You've earned 10 GB on Ente! 🎁"

	LoginSuccessSubject  = "New login to your Ente account"
	LoginSuccessTemplate = "on_login.html"

	FamilyNudgeEmailTemplate = "family_nudge.html"
	FamilyNudgeSubject       = "Invite your Family!"
	FamilyNudgeTemplateID    = "family_nudge"
)

type EmailNotificationController struct {
	UserRepo                           *repo.UserRepository
	LockController                     *lock.LockController
	NotificationHistoryRepo            *repo.NotificationHistoryRepository
	isSendingStorageLimitExceededMails bool
	FamilyRepo                         *repo.FamilyRepository
}

func (c *EmailNotificationController) OnFirstFileUpload(userID int64, userAgent string) {
	user, err := c.UserRepo.Get(userID)
	if err != nil {
		return
	}
	os := getOSFromUA(userAgent)
	template := WebAppFirstUploadTemplate
	if os == uasurfer.OSAndroid || os == uasurfer.OSiOS {
		template = MobileAppFirstUploadTemplate
	}
	err = email.SendTemplatedEmail([]string{user.Email}, "team@ente.io", "team@ente.io", FirstUploadEmailSubject, template, nil, nil)
	if err != nil {
		log.Error("Error sending first upload email", err)
	}
}

func getOSFromUA(ua string) uasurfer.OSName {
	return uasurfer.Parse(ua).OS.Name
}

func (c *EmailNotificationController) OnSuccessfulReferral(userID int64) {
	user, err := c.UserRepo.Get(userID)
	if err != nil {
		return
	}
	err = email.SendTemplatedEmail([]string{user.Email}, "team@ente.io", "team@ente.io", ReferralSuccessfulSubject, ReferralSuccessfulTemplate, nil, nil)
	if err != nil {
		log.Error("Error sending first upload email ", err)
	}
}

func (c *EmailNotificationController) OnLinkJoined(ownerID int64, otherUserID int64, role ente.CollectionParticipantRole) {
	user, err := c.UserRepo.Get(ownerID)
	if err != nil {
		return
	}
	otherUser, err := c.UserRepo.Get(otherUserID)
	if err != nil {
		return
	}
	data := map[string]interface{}{
		"OtherUserEmail": otherUser.Email,
		"Role":           role,
	}
	err = email.SendTemplatedEmailV2(
		[]string{user.Email}, "Ente", "team@ente.io",
		fmt.Sprintf("%s has joined your album", otherUser.Email), "base.html", "on_link_joined.html", data, nil)
	if err != nil {
		log.Error("Error sending link joined email ", err)
	}
}

func (c *EmailNotificationController) OnFilesCollected(userID int64) {
	user, err := c.UserRepo.Get(userID)
	if err != nil {
		return
	}
	lastNotificationTime, err := c.NotificationHistoryRepo.GetLastNotificationTime(userID, FilesCollectedTemplateID)
	logger := log.WithFields(log.Fields{
		"user_id": userID,
	})
	if err != nil {
		logger.Error("Could not fetch last notification time", err)
		return
	}
	if lastNotificationTime > time.MicrosecondsAfterMinutes(-FilesCollectedMuteDurationInMinutes) {
		logger.Info("Not notifying user about a collected file")
		return
	}
	lockName := "files_collected_" + strconv.FormatInt(userID, 10)
	lockStatus := c.LockController.TryLock(lockName, time.MicrosecondsAfterMinutes(FilesCollectedMuteDurationInMinutes))
	if !lockStatus {
		log.Error("Could not acquire lock to send file collected mails")
		return
	}
	defer c.LockController.ReleaseLock(lockName)
	logger.Info("Notifying about files collected")
	err = email.SendTemplatedEmail([]string{user.Email}, "team@ente.io", "team@ente.io", FilesCollectedSubject, FilesCollectedTemplate, nil, nil)
	if err != nil {
		log.Error("Error sending files collected email ", err)
	}
	c.NotificationHistoryRepo.SetLastNotificationTimeToNow(userID, FilesCollectedTemplateID)
}

func (c *EmailNotificationController) OnAccountUpgrade(userID int64) {
	user, err := c.UserRepo.Get(userID)
	if err != nil {
		log.Error("Could not find user to email", err)
		return
	}
	log.Info(fmt.Sprintf("Emailing on account upgrade %d", user.ID))
	err = email.SendTemplatedEmail([]string{user.Email}, "team@ente.io", "team@ente.io", SubscriptionUpgradedSubject, SubscriptionUpgradedTemplate, nil, nil)
	if err != nil {
		log.Error("Error sending files collected email ", err)
	}
}

func (c *EmailNotificationController) OnSubscriptionCancelled(userID int64) {
	user, err := c.UserRepo.Get(userID)
	if err != nil {
		log.Error("Could not find user to email", err)
		return
	}
	log.Info(fmt.Sprintf("Emailing on subscription cancellation %d", user.ID))
	err = email.SendTemplatedEmail([]string{user.Email}, "vishnu@ente.io", "vishnu@ente.io", SubscriptionCancelledSubject, SubscriptionCancelledTemplate, nil, nil)
	if err != nil {
		log.Error("Error sending email", err)
	}
}

func (c *EmailNotificationController) SendStorageAlerts() {
	if c.isSendingStorageLimitExceededMails {
		log.Info("Skipping sending storage limit exceeded mails as another instance is still running")
		return
	}
	c.setStorageLimitExceededMailerJobStatus(true)
	defer c.setStorageLimitExceededMailerJobStatus(false)
	lockStatus := c.LockController.TryLock(StorageLimitExceededMailLock, time.MicrosecondsAfterHours(24))
	if !lockStatus {
		log.Error("Could not acquire lock to send storage limit exceeded mails")
		return
	}
	defer c.LockController.ReleaseLock(StorageLimitExceededMailLock)

	// Notifs struct gets the list of both the users who have consumed
	// 90% storage and 100% of their subcriptions. Then, it ranges through
	// the slices of the both the users and inside this for loop, users from
	// both the slices are separately looped. This was done to avoid
	// duplication of a lot of code if both the users were ranged inside a loop
	// separately.
	storageAlertGroups := []struct {
		getListofSubscribers func() ([]ente.User, error)
		template             string
		subject              string
	}{
		{
			getListofSubscribers: func() ([]ente.User, error) {
				return c.UserRepo.GetUsersWithExceedingStorages(90)
			},
			template: StorageLimitExceededTemplate,
			subject:  StorageLimitExceededTemplate,
		},
		{
			getListofSubscribers: func() ([]ente.User, error) {
				return c.UserRepo.GetUsersWithExceedingStorages(100)
			},
			template: StorageLimitExceededTemplate,
			subject:  StorageLimitExceededSubject,
		},
	}
	for _, alertGroup := range storageAlertGroups {
		users, err := alertGroup.getListofSubscribers()
		if err != nil {
			log.WithError(err).Error("Failed to get list of users")
			continue
		}
		for _, u := range users {
			lastNotificationTime, err := c.NotificationHistoryRepo.GetLastNotificationTime(u.ID, StorageLimitExceededTemplateID)
			logger := log.WithFields(log.Fields{
				"user_id": u.ID,
			})
			if err != nil {
				logger.Error("Could not fetch last notification time", err)
				continue
			}
			if lastNotificationTime == 0 {
				logger.Info("Alerting about storage limit exceeded")
				err = email.SendTemplatedEmail([]string{u.Email}, "team@ente.io", "team@ente.io", alertGroup.subject, alertGroup.template, nil, nil)
				if err != nil {
					logger.Info("Error notifying", err)
					continue
				}
				c.NotificationHistoryRepo.SetLastNotificationTimeToNow(u.ID, StorageLimitExceededTemplateID)
			}
		}
	}
}

func (c *EmailNotificationController) setStorageLimitExceededMailerJobStatus(isSending bool) {
	c.isSendingStorageLimitExceededMails = isSending
}

func (c *EmailNotificationController) SendFamilyNudgeEmail() error {
	subscribedUsers, subUsersErr := c.UserRepo.GetSubscribedUsersWithoutFamily()
	if subUsersErr != nil {
		return stacktrace.Propagate(subUsersErr, "Failed to get subscribers")
	}

	batchSize := 100
	totalSubUsers := len(subscribedUsers)

	for i := range totalSubUsers {
		end := i + batchSize
		if end > totalSubUsers {
			end = totalSubUsers
		}
		batchUsers := subscribedUsers[i:end]
		for _, user := range batchUsers {
			isFamilyAdmin, err := c.UserRepo.GetFamilyAdminID(user.ID)
			if err != nil {
				return stacktrace.Propagate(err, "User is a family admin")
			}
			if isFamilyAdmin != nil {
				break
			}

			thirtyDays := 30 * 24 * t.Hour
			creationTime := t.Unix(0, user.CreationTime)
			timeSinceCreation := t.Since(creationTime)

			if timeSinceCreation >= thirtyDays {
				lastNudgeSent, err := c.NotificationHistoryRepo.GetLastNotificationTime(user.ID, FilesCollectedTemplateID)
				if err != nil {
					log.Error("Failed to set Notification History")
				}

				if lastNudgeSent == 0 {
					go func(userEmails []string) {
						err := email.SendTemplatedEmail(userEmails, "team@ente.io", "team@ente.io", SubscriptionCancelledSubject, SubscriptionCancelledTemplate, nil, nil)
						if err != nil {
							log.Error("Failed to send family nudge email: ", err)
						}
					}([]string{user.Email})
					c.NotificationHistoryRepo.SetLastNotificationTimeToNow(user.ID, FilesCollectedTemplateID)
				}
			}
		}
	}
	return nil
}
