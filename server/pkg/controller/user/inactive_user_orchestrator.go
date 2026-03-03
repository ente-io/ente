package user

import (
	"context"
	"errors"
	"fmt"
	"strings"
	stdtime "time"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/discord"
	"github.com/ente-io/museum/pkg/controller/lock"
	"github.com/ente-io/museum/pkg/repo"
	emergencyRepo "github.com/ente-io/museum/pkg/repo/emergency"
	emailUtil "github.com/ente-io/museum/pkg/utils/email"
	"github.com/ente-io/museum/pkg/utils/time"
	log "github.com/sirupsen/logrus"
)

const (
	InactiveUserDeletionJobLock = "inactive_user_deletion_mail_lock"

	inactiveUserDeletionBatchSize    = 500
	inactiveUserDeletionFromName     = "Ente"
	inactiveUserDeletionFromEmail    = "team@ente.io"
	inactiveUserDeletionBaseTemplate = "ente_base.html"

	InactiveUserDeletionWarn2mTemplateID = "inactive_user_deletion_warn_2m_v2"
	InactiveUserDeletionWarn1mTemplateID = "inactive_user_deletion_warn_1m_v2"
	InactiveUserDeletionWarn7dTemplateID = "inactive_user_deletion_warn_7d_v2"
	InactiveUserDeletionWarn1dTemplateID = "inactive_user_deletion_warn_1d_v2"
	InactiveUserDeletionFinalTemplateID  = "inactive_user_deletion_confirm_13m_v2"

	inactiveUserDeletionWarn2mTemplate = "inactive-user-deletion/warn_2m.html"
	inactiveUserDeletionWarn1mTemplate = "inactive-user-deletion/warn_1m.html"
	inactiveUserDeletionWarn7dTemplate = "inactive-user-deletion/warn_7d.html"
	inactiveUserDeletionWarn1dTemplate = "inactive-user-deletion/warn_1d.html"
	inactiveUserDeletionFinalTemplate  = "inactive-user-deletion/confirm_13m.html"

	inactiveUserDeletionWarn2mSubject = "Your Ente account is scheduled for deletion due to inactivity"
	inactiveUserDeletionWarn1mSubject = "Reminder: Your Ente account will be deleted in 30 days due to inactivity"
	inactiveUserDeletionWarn7dSubject = "Reminder: Your Ente account will be deleted in 7 days due to inactivity"
	inactiveUserDeletionWarn1dSubject = "REMINDER: Your Ente account will be deleted tomorrow due to inactivity"
	inactiveUserDeletionFinalSubject  = "Your Ente account has been deleted"
)

const (
	inactiveUserOneDayInMicroSeconds = 24 * time.MicroSecondsInOneHour

	// 13 months is modeled as 395 days (365 + 30). The first warning (2 months
	// before deletion) starts at 335 days of inactivity.
	inactiveUserThirteenMonthsInMicroSeconds = (365 + 30) * inactiveUserOneDayInMicroSeconds
	inactiveUserWarn2MonthsInMicroSeconds    = inactiveUserThirteenMonthsInMicroSeconds - (60 * inactiveUserOneDayInMicroSeconds)

	// Stage progression is based on when the previous stage email was sent.
	inactiveUserGap2mTo1m    = 30 * inactiveUserOneDayInMicroSeconds
	inactiveUserGap1mTo7d    = 23 * inactiveUserOneDayInMicroSeconds
	inactiveUserGap7dTo1d    = 6 * inactiveUserOneDayInMicroSeconds
	inactiveUserGap1dToFinal = inactiveUserOneDayInMicroSeconds
)

var inactiveUserDeletionTemplateIDs = []string{
	InactiveUserDeletionWarn2mTemplateID,
	InactiveUserDeletionWarn1mTemplateID,
	InactiveUserDeletionWarn7dTemplateID,
	InactiveUserDeletionWarn1dTemplateID,
	InactiveUserDeletionFinalTemplateID,
}

type inactivityEmailStage string

const (
	inactivityEmailStageNone   inactivityEmailStage = ""
	inactivityEmailStageWarn2m inactivityEmailStage = "warn_2m"
	inactivityEmailStageWarn1m inactivityEmailStage = "warn_1m"
	inactivityEmailStageWarn7d inactivityEmailStage = "warn_7d"
	inactivityEmailStageWarn1d inactivityEmailStage = "warn_1d"
	inactivityEmailStageFinal  inactivityEmailStage = "confirm_13m"
)

type inactivityEmailStageConfig struct {
	TemplateID   string
	TemplateName string
	Subject      string
	IsFinal      bool
}

// InactiveUserOrchestrator sends inactivity warning emails and final account
// deletion notifications for users who stay inactive across all apps.
type InactiveUserOrchestrator struct {
	UserRepo                *repo.UserRepository
	NotificationHistoryRepo *repo.NotificationHistoryRepository
	EmergencyContactRepo    *emergencyRepo.Repository
	LockController          *lock.LockController
	DiscordController       *discord.DiscordController
	UserController          *UserController
}

func NewInactiveUserOrchestrator(
	userRepo *repo.UserRepository,
	notificationHistoryRepo *repo.NotificationHistoryRepository,
	emergencyContactRepo *emergencyRepo.Repository,
	lockController *lock.LockController,
	discordController *discord.DiscordController,
	userController *UserController,
) *InactiveUserOrchestrator {
	return &InactiveUserOrchestrator{
		UserRepo:                userRepo,
		NotificationHistoryRepo: notificationHistoryRepo,
		EmergencyContactRepo:    emergencyContactRepo,
		LockController:          lockController,
		DiscordController:       discordController,
		UserController:          userController,
	}
}

func (c *InactiveUserOrchestrator) ProcessInactiveUsers() {
	lockUntil := time.MicrosecondsAfterHours(24)
	if !c.LockController.TryLock(InactiveUserDeletionJobLock, lockUntil) {
		log.Info("Skipping inactive user processing because another instance is running")
		return
	}
	defer c.LockController.ReleaseLock(InactiveUserDeletionJobLock)

	now := time.Microseconds()
	beforeTime := now - inactiveUserWarn2MonthsInMicroSeconds
	var afterUserID int64
	processedUsers := 0
	sentEmails := 0

	for {
		candidates, err := c.UserRepo.GetActiveUsersByLastActivityBefore(beforeTime, afterUserID, inactiveUserDeletionBatchSize)
		if err != nil {
			log.WithError(err).Error("Failed to fetch inactive users")
			return
		}
		if len(candidates) == 0 {
			break
		}

		for _, candidate := range candidates {
			afterUserID = candidate.UserID
			processedUsers++
			sent, err := c.processCandidate(candidate, now)
			if err != nil {
				log.WithError(err).WithField("user_id", candidate.UserID).Error("Failed to process inactive user candidate")
				continue
			}
			if sent {
				sentEmails++
			}
		}
	}

	log.WithFields(log.Fields{
		"processed_users": processedUsers,
		"sent_emails":     sentEmails,
	}).Info("Completed inactive user processing")
}

func (c *InactiveUserOrchestrator) processCandidate(candidate repo.UserInactivityCandidate, now int64) (bool, error) {
	user, err := c.UserRepo.Get(candidate.UserID)
	if err != nil {
		if errors.Is(err, ente.ErrUserDeleted) {
			return false, nil
		}
		return false, err
	}

	if !isEnteDomainRolloutUser(user.Email) {
		return false, nil
	}

	hasActivePaidEntitlement, err := c.hasActivePaidEntitlement(user.ID)
	if err != nil {
		return false, err
	}
	if hasActivePaidEntitlement {
		log.WithField("user_id", user.ID).Info("Skipping inactive user processing because user has active paid entitlement")
		return false, nil
	}

	lastActivity, found, err := c.UserRepo.GetLatestActivity(user.ID)
	if err != nil {
		return false, err
	}
	if !found {
		// User is no longer active.
		return false, nil
	}

	stage, err := c.resolveNextStage(user.ID, lastActivity, now)
	if err != nil {
		return false, err
	}
	if stage == inactivityEmailStageNone {
		return false, nil
	}

	config := inactivityStageConfig(stage)
	if config.TemplateID == "" {
		return false, nil
	}

	if config.IsFinal {
		if c.UserController == nil {
			return false, fmt.Errorf("inactive user deletion requires user controller")
		}
		hasActivePaidEntitlement, err := c.hasActivePaidEntitlement(user.ID)
		if err != nil {
			return false, err
		}
		if hasActivePaidEntitlement {
			log.WithField("user_id", user.ID).Info("Skipping inactive user deletion because user has active paid entitlement")
			return false, nil
		}

		// Re-check right before deletion to avoid deleting users who became active
		// after earlier reads in long processing runs.
		latestActivity, latestFound, err := c.UserRepo.GetLatestActivity(user.ID)
		if err != nil {
			return false, err
		}
		if !latestFound {
			return false, nil
		}
		latestStage, err := c.resolveNextStage(user.ID, latestActivity, now)
		if err != nil {
			return false, err
		}
		if latestStage != inactivityEmailStageFinal {
			log.WithField("user_id", user.ID).Info("Skipping inactive user deletion because user is no longer in final stage")
			return false, nil
		}
		if c.EmergencyContactRepo != nil {
			hasActiveLegacyContact, err := c.EmergencyContactRepo.HasActiveLegacyContact(context.Background(), user.ID)
			if err != nil {
				return false, err
			}
			if hasActiveLegacyContact {
				c.DiscordController.NotifyAdminAction(
					fmt.Sprintf("Inactive user %d (%s) deletion paused at %s due to active legacy contact",
						user.ID, user.Email, stdtime.UnixMicro(now).UTC().Format(stdtime.RFC3339)))
				log.WithField("user_id", user.ID).Info("Skipping inactive user deletion because user has active legacy contact configured")
				return false, nil
			}
		}

		deleteLogger := log.WithFields(log.Fields{
			"user_id": user.ID,
			"req_ctx": "inactive_account_deletion",
		})
		if _, err := c.UserController.HandleAutomatedAccountDeletion(context.Background(), user.ID, deleteLogger); err != nil {
			return false, err
		}
	}

	deletionDate := formatDeletionDateForStage(stage, now)
	templateData := map[string]interface{}{
		"Email":        user.Email,
		"DeletionDate": deletionDate,
	}
	if err := emailUtil.SendTemplatedEmailV2(
		[]string{user.Email},
		inactiveUserDeletionFromName,
		inactiveUserDeletionFromEmail,
		config.Subject,
		inactiveUserDeletionBaseTemplate,
		config.TemplateName,
		templateData,
		nil,
	); err != nil {
		return false, err
	}

	if err := c.NotificationHistoryRepo.SetLastNotificationTimeToNow(user.ID, config.TemplateID); err != nil {
		return false, err
	}

	log.WithFields(log.Fields{
		"user_id":       user.ID,
		"email":         user.Email,
		"template_id":   config.TemplateID,
		"deletion_date": deletionDate,
	}).Info("Sent inactive user email")

	if config.IsFinal {
		c.DiscordController.NotifyAdminAction(
			fmt.Sprintf("Inactive user %d (%s) reached 13 months inactivity and account deletion was initiated",
				user.ID, user.Email))
	}

	return true, nil
}

func (c *InactiveUserOrchestrator) hasActivePaidEntitlement(userID int64) (bool, error) {
	err := c.UserController.BillingController.HasActiveSelfOrFamilySubscription(userID, true)
	if err == nil {
		return true, nil
	}
	if errors.Is(err, ente.ErrNoActiveSubscription) || errors.Is(err, ente.ErrSharingDisabledForFreeAccounts) {
		return false, nil
	}
	return false, err
}

func (c *InactiveUserOrchestrator) resolveNextStage(userID int64, lastActivity int64, now int64) (inactivityEmailStage, error) {
	history, err := c.NotificationHistoryRepo.GetLastNotificationTimes(userID, inactiveUserDeletionTemplateIDs)
	if err != nil {
		return inactivityEmailStageNone, err
	}
	return nextInactivityEmailStage(lastActivity, now, history), nil
}

func nextInactivityEmailStage(lastActivity int64, now int64, history map[string]int64) inactivityEmailStage {
	if now-lastActivity < inactiveUserWarn2MonthsInMicroSeconds {
		return inactivityEmailStageNone
	}

	sent2m := history[InactiveUserDeletionWarn2mTemplateID]
	if sent2m <= lastActivity {
		return inactivityEmailStageWarn2m
	}

	sentFinal := history[InactiveUserDeletionFinalTemplateID]
	if sentFinal > lastActivity {
		return inactivityEmailStageNone
	}

	sent1m := history[InactiveUserDeletionWarn1mTemplateID]
	if sent1m <= lastActivity {
		if now >= sent2m+inactiveUserGap2mTo1m {
			return inactivityEmailStageWarn1m
		}
		return inactivityEmailStageNone
	}

	sent7d := history[InactiveUserDeletionWarn7dTemplateID]
	if sent7d <= lastActivity {
		if now >= sent1m+inactiveUserGap1mTo7d {
			return inactivityEmailStageWarn7d
		}
		return inactivityEmailStageNone
	}

	sent1d := history[InactiveUserDeletionWarn1dTemplateID]
	if sent1d <= lastActivity {
		if now >= sent7d+inactiveUserGap7dTo1d {
			return inactivityEmailStageWarn1d
		}
		return inactivityEmailStageNone
	}

	if now >= sent1d+inactiveUserGap1dToFinal {
		return inactivityEmailStageFinal
	}
	return inactivityEmailStageNone
}

func inactivityStageConfig(stage inactivityEmailStage) inactivityEmailStageConfig {
	switch stage {
	case inactivityEmailStageWarn2m:
		return inactivityEmailStageConfig{
			TemplateID:   InactiveUserDeletionWarn2mTemplateID,
			TemplateName: inactiveUserDeletionWarn2mTemplate,
			Subject:      inactiveUserDeletionWarn2mSubject,
		}
	case inactivityEmailStageWarn1m:
		return inactivityEmailStageConfig{
			TemplateID:   InactiveUserDeletionWarn1mTemplateID,
			TemplateName: inactiveUserDeletionWarn1mTemplate,
			Subject:      inactiveUserDeletionWarn1mSubject,
		}
	case inactivityEmailStageWarn7d:
		return inactivityEmailStageConfig{
			TemplateID:   InactiveUserDeletionWarn7dTemplateID,
			TemplateName: inactiveUserDeletionWarn7dTemplate,
			Subject:      inactiveUserDeletionWarn7dSubject,
		}
	case inactivityEmailStageWarn1d:
		return inactivityEmailStageConfig{
			TemplateID:   InactiveUserDeletionWarn1dTemplateID,
			TemplateName: inactiveUserDeletionWarn1dTemplate,
			Subject:      inactiveUserDeletionWarn1dSubject,
		}
	case inactivityEmailStageFinal:
		return inactivityEmailStageConfig{
			TemplateID:   InactiveUserDeletionFinalTemplateID,
			TemplateName: inactiveUserDeletionFinalTemplate,
			Subject:      inactiveUserDeletionFinalSubject,
			IsFinal:      true,
		}
	default:
		return inactivityEmailStageConfig{}
	}
}

func isEnteDomainRolloutUser(email string) bool {
	return strings.HasSuffix(strings.ToLower(strings.TrimSpace(email)), "@ente.io")
}

func formatDeletionDateForStage(stage inactivityEmailStage, now int64) string {
	var daysUntilDeletion int64
	switch stage {
	case inactivityEmailStageWarn2m:
		daysUntilDeletion = 60
	case inactivityEmailStageWarn1m:
		daysUntilDeletion = 30
	case inactivityEmailStageWarn7d:
		daysUntilDeletion = 7
	case inactivityEmailStageWarn1d:
		daysUntilDeletion = 1
	case inactivityEmailStageFinal:
		daysUntilDeletion = 0
	}
	deletionTime := stdtime.UnixMicro(now + daysUntilDeletion*inactiveUserOneDayInMicroSeconds).UTC()
	return deletionTime.Format("02 Jan 2006")
}
