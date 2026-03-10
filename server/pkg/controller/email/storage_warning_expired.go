package email

import "github.com/ente-io/museum/pkg/utils/time"

const (
	storageWarningExpiredTemplate = "storage_warning_expired.html"

	storageWarningExpiredDeletionDelay   = 120 * 24 * time.MicroSecondsInOneHour
	storageWarningExpiredWarning30Delay  = 30 * 24 * time.MicroSecondsInOneHour
	storageWarningExpiredWarning60Delay  = 60 * 24 * time.MicroSecondsInOneHour
	storageWarningExpiredWarning90Delay  = 90 * 24 * time.MicroSecondsInOneHour
	storageWarningExpiredWarning119Delay = 119 * 24 * time.MicroSecondsInOneHour

	storageWarningExpired30TemplateID  = "family_storage_warning_expired_30d"
	storageWarningExpired60TemplateID  = "family_storage_warning_expired_60d"
	storageWarningExpired90TemplateID  = "family_storage_warning_expired_90d"
	storageWarningExpired119TemplateID = "family_storage_warning_expired_119d"

	storageWarningExpired30Subject  = "Action needed: Your Ente subscription has expired"
	storageWarningExpired60Subject  = "Reminder: Your Ente data is scheduled for deletion"
	storageWarningExpired90Subject  = "30-day reminder: Your Ente data will be deleted in 30 days"
	storageWarningExpired119Subject = "Final reminder: Your Ente data will be deleted tomorrow"
)

type expiredWarningStage string

const (
	expiredWarningStageNone expiredWarningStage = "none"
	expiredWarningStage30   expiredWarningStage = "expired_30d"
	expiredWarningStage60   expiredWarningStage = "expired_60d"
	expiredWarningStage90   expiredWarningStage = "expired_90d"
	expiredWarningStage119  expiredWarningStage = "expired_119d"
)

func expiredWarningTemplateDetails(stage expiredWarningStage) (templateID string, templateName string, subject string, ok bool) {
	switch stage {
	case expiredWarningStage30:
		return storageWarningExpired30TemplateID, storageWarningExpiredTemplate, storageWarningExpired30Subject, true
	case expiredWarningStage60:
		return storageWarningExpired60TemplateID, storageWarningExpiredTemplate, storageWarningExpired60Subject, true
	case expiredWarningStage90:
		return storageWarningExpired90TemplateID, storageWarningExpiredTemplate, storageWarningExpired90Subject, true
	case expiredWarningStage119:
		return storageWarningExpired119TemplateID, storageWarningExpiredTemplate, storageWarningExpired119Subject, true
	default:
		return "", "", "", false
	}
}

func expiredWarningTemplateIDs() []string {
	return []string{
		storageWarningExpired30TemplateID,
		storageWarningExpired60TemplateID,
		storageWarningExpired90TemplateID,
		storageWarningExpired119TemplateID,
	}
}

func resolveExpiredWarningStage(effectiveExpiry int64, now int64, history map[string]int64) expiredWarningStage {
	if effectiveExpiry <= 0 || effectiveExpiry > now {
		return expiredWarningStageNone
	}

	daysSinceExpiry := now - effectiveExpiry
	if daysSinceExpiry >= storageWarningExpiredWarning119Delay &&
		!storageWarningTemplateSentInCycle(history, storageWarningExpired119TemplateID, effectiveExpiry) {
		return expiredWarningStage119
	}
	if daysSinceExpiry >= storageWarningExpiredWarning90Delay &&
		!storageWarningTemplateSentInCycle(history, storageWarningExpired90TemplateID, effectiveExpiry) {
		return expiredWarningStage90
	}
	if daysSinceExpiry >= storageWarningExpiredWarning60Delay &&
		!storageWarningTemplateSentInCycle(history, storageWarningExpired60TemplateID, effectiveExpiry) {
		return expiredWarningStage60
	}
	if daysSinceExpiry >= storageWarningExpiredWarning30Delay &&
		!storageWarningTemplateSentInCycle(history, storageWarningExpired30TemplateID, effectiveExpiry) {
		return expiredWarningStage30
	}
	return expiredWarningStageNone
}

func expiredWarningAutoDeleteDate(effectiveExpiry int64, stage expiredWarningStage, now int64) int64 {
	autoDeleteDate := effectiveExpiry + storageWarningExpiredDeletionDelay
	if stage == expiredWarningStage119 && autoDeleteDate <= now {
		return now + storageWarningOneDayInMicroseconds
	}
	return autoDeleteDate
}
