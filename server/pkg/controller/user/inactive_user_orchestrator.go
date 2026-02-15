package user

import (
	"errors"
	"fmt"
	"strings"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/discord"
	"github.com/ente-io/museum/pkg/controller/lock"
	"github.com/ente-io/museum/pkg/repo"
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

	InactiveUserDeletionWarn11mTemplateID   = "inactive_user_deletion_warn_11m"
	InactiveUserDeletionWarn12m7dTemplateID = "inactive_user_deletion_warn_12m_7d"
	InactiveUserDeletionWarn12m1dTemplateID = "inactive_user_deletion_warn_12m_1d"
	InactiveUserDeletionFinalTemplateID     = "inactive_user_deletion_confirm_12m"

	inactiveUserDeletionWarn11mTemplate   = "inactive-user-deletion/warn_11m.html"
	inactiveUserDeletionWarn12m7dTemplate = "inactive-user-deletion/warn_12m_7d.html"
	inactiveUserDeletionWarn12m1dTemplate = "inactive-user-deletion/warn_12m_1d.html"
	inactiveUserDeletionFinalTemplate     = "inactive-user-deletion/confirm_12m.html"

	inactiveUserDeletionWarn11mSubject   = "Your Ente account has been inactive"
	inactiveUserDeletionWarn12m7dSubject = "Reminder: your Ente account is still inactive"
	inactiveUserDeletionWarn12m1dSubject = "Final reminder: your Ente account is inactive"
	inactiveUserDeletionFinalSubject     = "Your Ente account is marked for manual deletion review"
)

const (
	inactiveUserOneDayInMicroSeconds = 24 * time.MicroSecondsInOneHour

	// 12 months is modeled as 365 days. The first stage (11 months) maps to
	// 30 days before 12 months to preserve the desired 23/6/1 day replay gaps.
	inactiveUserTwelveMonthsInMicroSeconds = 365 * inactiveUserOneDayInMicroSeconds
	inactiveUserWarn11MonthsInMicroSeconds = inactiveUserTwelveMonthsInMicroSeconds - (30 * inactiveUserOneDayInMicroSeconds)

	inactiveUserGap11mTo12mMinus7d = 23 * inactiveUserOneDayInMicroSeconds
	inactiveUserGap12mMinus7dTo1d  = 6 * inactiveUserOneDayInMicroSeconds
	inactiveUserGap12mMinus1dTo12m = inactiveUserOneDayInMicroSeconds
)

var inactiveUserDeletionTemplateIDs = []string{
	InactiveUserDeletionWarn11mTemplateID,
	InactiveUserDeletionWarn12m7dTemplateID,
	InactiveUserDeletionWarn12m1dTemplateID,
	InactiveUserDeletionFinalTemplateID,
}

type inactivityEmailStage string

const (
	inactivityEmailStageNone      inactivityEmailStage = ""
	inactivityEmailStageWarn11m   inactivityEmailStage = "warn_11m"
	inactivityEmailStageWarn12m7d inactivityEmailStage = "warn_12m_7d"
	inactivityEmailStageWarn12m1d inactivityEmailStage = "warn_12m_1d"
	inactivityEmailStageFinal     inactivityEmailStage = "confirm_12m"
)

type inactivityEmailStageConfig struct {
	TemplateID   string
	TemplateName string
	Subject      string
	IsFinal      bool
}

// InactiveUserOrchestrator sends inactivity warning emails and final manual
// deletion reminders for users who stay inactive across all apps.
type InactiveUserOrchestrator struct {
	UserRepo                *repo.UserRepository
	NotificationHistoryRepo *repo.NotificationHistoryRepository
	LockController          *lock.LockController
	DiscordController       *discord.DiscordController
}

func NewInactiveUserOrchestrator(
	userRepo *repo.UserRepository,
	notificationHistoryRepo *repo.NotificationHistoryRepository,
	lockController *lock.LockController,
	discordController *discord.DiscordController,
) *InactiveUserOrchestrator {
	return &InactiveUserOrchestrator{
		UserRepo:                userRepo,
		NotificationHistoryRepo: notificationHistoryRepo,
		LockController:          lockController,
		DiscordController:       discordController,
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
	beforeTime := now - inactiveUserWarn11MonthsInMicroSeconds
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

	stage, err := c.resolveNextStage(user.ID, candidate.LastActivity, now)
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

	templateData := map[string]interface{}{
		"Email": user.Email,
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
		"user_id":     user.ID,
		"template_id": config.TemplateID,
	}).Info("Sent inactive user email")

	if config.IsFinal {
		c.DiscordController.NotifyAdminAction(
			fmt.Sprintf("Inactive user %d (%s) reached 12 months inactivity and was sent final warning for manual deletion review",
				user.ID, user.Email))
	}

	return true, nil
}

func (c *InactiveUserOrchestrator) resolveNextStage(userID int64, lastActivity int64, now int64) (inactivityEmailStage, error) {
	history, err := c.NotificationHistoryRepo.GetLastNotificationTimes(userID, inactiveUserDeletionTemplateIDs)
	if err != nil {
		return inactivityEmailStageNone, err
	}
	return nextInactivityEmailStage(lastActivity, now, history), nil
}

func nextInactivityEmailStage(lastActivity int64, now int64, history map[string]int64) inactivityEmailStage {
	if now-lastActivity < inactiveUserWarn11MonthsInMicroSeconds {
		return inactivityEmailStageNone
	}

	sent11m := history[InactiveUserDeletionWarn11mTemplateID]
	if sent11m <= lastActivity {
		return inactivityEmailStageWarn11m
	}

	sentFinal := history[InactiveUserDeletionFinalTemplateID]
	if sentFinal > lastActivity {
		return inactivityEmailStageNone
	}

	sent12mMinus7d := history[InactiveUserDeletionWarn12m7dTemplateID]
	if sent12mMinus7d <= lastActivity {
		if now >= sent11m+inactiveUserGap11mTo12mMinus7d {
			return inactivityEmailStageWarn12m7d
		}
		return inactivityEmailStageNone
	}

	sent12mMinus1d := history[InactiveUserDeletionWarn12m1dTemplateID]
	if sent12mMinus1d <= lastActivity {
		if now >= sent12mMinus7d+inactiveUserGap12mMinus7dTo1d {
			return inactivityEmailStageWarn12m1d
		}
		return inactivityEmailStageNone
	}

	if now >= sent12mMinus1d+inactiveUserGap12mMinus1dTo12m {
		return inactivityEmailStageFinal
	}
	return inactivityEmailStageNone
}

func inactivityStageConfig(stage inactivityEmailStage) inactivityEmailStageConfig {
	switch stage {
	case inactivityEmailStageWarn11m:
		return inactivityEmailStageConfig{
			TemplateID:   InactiveUserDeletionWarn11mTemplateID,
			TemplateName: inactiveUserDeletionWarn11mTemplate,
			Subject:      inactiveUserDeletionWarn11mSubject,
		}
	case inactivityEmailStageWarn12m7d:
		return inactivityEmailStageConfig{
			TemplateID:   InactiveUserDeletionWarn12m7dTemplateID,
			TemplateName: inactiveUserDeletionWarn12m7dTemplate,
			Subject:      inactiveUserDeletionWarn12m7dSubject,
		}
	case inactivityEmailStageWarn12m1d:
		return inactivityEmailStageConfig{
			TemplateID:   InactiveUserDeletionWarn12m1dTemplateID,
			TemplateName: inactiveUserDeletionWarn12m1dTemplate,
			Subject:      inactiveUserDeletionWarn12m1dSubject,
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
