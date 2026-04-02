package email

import (
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/time"
)

const (
	storageWarningExpiredTemplate                  = "storage-warning/storage_warning_expired.html"
	storageWarningExpiredScheduledDeletionTemplate = "storage-warning/storage_warning_expired_scheduled_deletion.html"

	storageWarningExpiredAnchorDelay     = 30 * 24 * time.MicroSecondsInOneHour
	storageWarningExpiredDeletionDelay   = 120 * 24 * time.MicroSecondsInOneHour
	storageWarningExpiredWarning0Delay   = 0
	storageWarningExpiredWarning30Delay  = 30 * 24 * time.MicroSecondsInOneHour
	storageWarningExpiredWarning60Delay  = 60 * 24 * time.MicroSecondsInOneHour
	storageWarningExpiredWarning90Delay  = 90 * 24 * time.MicroSecondsInOneHour
	storageWarningExpiredWarning119Delay = 119 * 24 * time.MicroSecondsInOneHour

	storageWarningExpired0TemplateID   = "storage_warning_expired_0d"
	storageWarningExpired30TemplateID  = "storage_warning_expired_30d"
	storageWarningExpired60TemplateID  = "storage_warning_expired_60d"
	storageWarningExpired90TemplateID  = "storage_warning_expired_90d"
	storageWarningExpired119TemplateID = "storage_warning_expired_119d"

	storageWarningExpired0Subject                 = "Action needed: Your Ente subscription has expired"
	storageWarningExpired30Subject                = "Reminder: Your Ente data is scheduled for deletion"
	storageWarningExpired60Subject                = "Reminder: Renew your Ente plan to avoid data deletion"
	storageWarningExpired90Subject                = "30-day reminder: Your Ente data will be deleted in 30 days"
	storageWarningExpired119Subject               = "Final reminder: Your Ente data will be deleted tomorrow"
	storageWarningExpiredScheduledDeletionSubject = "Your Ente data is scheduled for deletion"
)

type expiredWarningStage string

const (
	expiredWarningStageNone              expiredWarningStage = "none"
	expiredWarningStage0                 expiredWarningStage = "expired_0d"
	expiredWarningStage30                expiredWarningStage = "expired_30d"
	expiredWarningStage60                expiredWarningStage = "expired_60d"
	expiredWarningStage90                expiredWarningStage = "expired_90d"
	expiredWarningStage119               expiredWarningStage = "expired_119d"
	expiredWarningStageScheduledDeletion expiredWarningStage = "expired_scheduled_deletion"
)

func expiredWarningTemplateDetails(stage expiredWarningStage) (templateID string, templateName string, subject string, ok bool) {
	switch stage {
	case expiredWarningStage0:
		return storageWarningExpired0TemplateID, storageWarningExpiredTemplate, storageWarningExpired0Subject, true
	case expiredWarningStage30:
		return storageWarningExpired30TemplateID, storageWarningExpiredTemplate, storageWarningExpired30Subject, true
	case expiredWarningStage60:
		return storageWarningExpired60TemplateID, storageWarningExpiredTemplate, storageWarningExpired60Subject, true
	case expiredWarningStage90:
		return storageWarningExpired90TemplateID, storageWarningExpiredTemplate, storageWarningExpired90Subject, true
	case expiredWarningStage119:
		return storageWarningExpired119TemplateID, storageWarningExpiredTemplate, storageWarningExpired119Subject, true
	case expiredWarningStageScheduledDeletion:
		return repo.StorageWarningExpiredScheduledDeletionTemplateID, storageWarningExpiredScheduledDeletionTemplate, storageWarningExpiredScheduledDeletionSubject, true
	default:
		return "", "", "", false
	}
}

func expiredWarningTemplateIDs() []string {
	return []string{
		storageWarningExpired0TemplateID,
		storageWarningExpired30TemplateID,
		storageWarningExpired60TemplateID,
		storageWarningExpired90TemplateID,
		storageWarningExpired119TemplateID,
		repo.StorageWarningExpiredScheduledDeletionTemplateID,
	}
}

// Template IDs use days since the expired-warning anchor, which is raw expiry + 30 days.
func resolveExpiredWarningStage(expiredWarningAnchor int64, now int64, history map[string]int64) expiredWarningStage {
	if expiredWarningAnchor <= 0 || expiredWarningAnchor > now {
		return expiredWarningStageNone
	}

	daysSinceAnchor := now - expiredWarningAnchor
	if daysSinceAnchor >= storageWarningExpiredWarning0Delay &&
		!storageWarningTemplateSentInCycle(history, storageWarningExpired0TemplateID, expiredWarningAnchor) {
		return expiredWarningStage0
	}
	if daysSinceAnchor >= storageWarningExpiredWarning30Delay &&
		!storageWarningTemplateSentInCycle(history, storageWarningExpired30TemplateID, expiredWarningAnchor) {
		return expiredWarningStage30
	}
	if daysSinceAnchor >= storageWarningExpiredWarning60Delay &&
		!storageWarningTemplateSentInCycle(history, storageWarningExpired60TemplateID, expiredWarningAnchor) {
		return expiredWarningStage60
	}
	if daysSinceAnchor >= storageWarningExpiredWarning90Delay &&
		!storageWarningTemplateSentInCycle(history, storageWarningExpired90TemplateID, expiredWarningAnchor) {
		return expiredWarningStage90
	}
	if daysSinceAnchor >= storageWarningExpiredWarning119Delay &&
		!storageWarningTemplateSentInCycle(history, storageWarningExpired119TemplateID, expiredWarningAnchor) {
		return expiredWarningStage119
	}
	if daysSinceAnchor >= storageWarningExpiredDeletionDelay &&
		!storageWarningTemplateSentInCycle(history, repo.StorageWarningExpiredScheduledDeletionTemplateID, expiredWarningAnchor) {
		return expiredWarningStageScheduledDeletion
	}
	return expiredWarningStageNone
}

func expiredWarningAutoDeleteDate(expiredWarningAnchor int64, stage expiredWarningStage, now int64) int64 {
	autoDeleteDate := expiredWarningAnchor + storageWarningExpiredDeletionDelay
	if stage == expiredWarningStage119 && autoDeleteDate <= now {
		return now + storageWarningOneDayInMicroseconds
	}
	return autoDeleteDate
}

func expiredWarningAnchorFromSubscriptionExpiry(subscriptionExpiry int64) int64 {
	if subscriptionExpiry <= 0 {
		return 0
	}
	return subscriptionExpiry + storageWarningExpiredAnchorDelay
}
