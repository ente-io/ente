package email

import (
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/time"
)

const (
	StorageWarningActiveOverageAnchorTemplateID          = "storage_warning_active_overage"
	storageWarningActiveOverageTemplate                  = "storage-warning/storage_warning_active_overage.html"
	storageWarningActiveOverageScheduledDeletionTemplate = "storage-warning/storage_warning_active_overage_scheduled_deletion.html"
	storageWarningActiveOverageDeletionDelay             = 90 * 24 * time.MicroSecondsInOneHour
	storageWarningActiveOverageWarning30Delay            = 30 * 24 * time.MicroSecondsInOneHour
	storageWarningActiveOverageWarning60Delay            = 60 * 24 * time.MicroSecondsInOneHour
	storageWarningActiveOverageWarning89Delay            = 89 * 24 * time.MicroSecondsInOneHour
	storageWarningActiveOverage30TemplateID              = "storage_warning_active_overage_30d"
	storageWarningActiveOverage60TemplateID              = "storage_warning_active_overage_60d"
	storageWarningActiveOverage89TemplateID              = "storage_warning_active_overage_89d"
	storageWarningActiveOverage0Subject                  = "Action needed: Reduce usage or upgrade your Ente plan"
	storageWarningActiveOverage30Subject                 = "Reminder: Your Ente data is scheduled for deletion due to overusage"
	storageWarningActiveOverage60Subject                 = "30-day reminder: Your Ente data will be deleted in 30 days due to overusage"
	storageWarningActiveOverage89Subject                 = "Final reminder: Your Ente data will be deleted tomorrow due to overusage"
	storageWarningActiveOverageScheduledDeletionSubject  = "Your Ente data is scheduled for deletion due to overusage"
)

type activeOverageWarningStage string

const (
	activeOverageWarningStageNone              activeOverageWarningStage = "none"
	activeOverageWarningStage0                 activeOverageWarningStage = "active_overage_0d"
	activeOverageWarningStage30                activeOverageWarningStage = "active_overage_30d"
	activeOverageWarningStage60                activeOverageWarningStage = "active_overage_60d"
	activeOverageWarningStage89                activeOverageWarningStage = "active_overage_89d"
	activeOverageWarningStageScheduledDeletion activeOverageWarningStage = "active_overage_scheduled_deletion"
)

type activeOverageWarningResolution struct {
	Stage      activeOverageWarningStage
	CycleStart int64
}

func activeOverageWarningTemplateDetails(stage activeOverageWarningStage) (templateID string, templateName string, subject string, ok bool) {
	switch stage {
	case activeOverageWarningStage0:
		return StorageWarningActiveOverageAnchorTemplateID, storageWarningActiveOverageTemplate, storageWarningActiveOverage0Subject, true
	case activeOverageWarningStage30:
		return storageWarningActiveOverage30TemplateID, storageWarningActiveOverageTemplate, storageWarningActiveOverage30Subject, true
	case activeOverageWarningStage60:
		return storageWarningActiveOverage60TemplateID, storageWarningActiveOverageTemplate, storageWarningActiveOverage60Subject, true
	case activeOverageWarningStage89:
		return storageWarningActiveOverage89TemplateID, storageWarningActiveOverageTemplate, storageWarningActiveOverage89Subject, true
	case activeOverageWarningStageScheduledDeletion:
		return repo.StorageWarningActiveOverageScheduledDeletionTemplateID, storageWarningActiveOverageScheduledDeletionTemplate, storageWarningActiveOverageScheduledDeletionSubject, true
	default:
		return "", "", "", false
	}
}

func activeOverageWarningTemplateIDs() []string {
	return []string{
		StorageWarningActiveOverageAnchorTemplateID,
		storageWarningActiveOverage30TemplateID,
		storageWarningActiveOverage60TemplateID,
		storageWarningActiveOverage89TemplateID,
		repo.StorageWarningActiveOverageScheduledDeletionTemplateID,
	}
}

func resolveActiveOverageWarningStage(now int64, history map[string]int64) activeOverageWarningStage {
	return resolveActiveOverageWarning(now, history).Stage
}

func resolveActiveOverageWarning(now int64, history map[string]int64) activeOverageWarningResolution {
	cycleStart := history[StorageWarningActiveOverageAnchorTemplateID]
	scheduledDeletionSentAt := history[repo.StorageWarningActiveOverageScheduledDeletionTemplateID]
	if scheduledDeletionSentAt > 0 {
		if cycleStart <= 0 {
			cycleStart = scheduledDeletionSentAt
		}
		return activeOverageWarningResolution{
			Stage:      activeOverageWarningStageNone,
			CycleStart: cycleStart,
		}
	}
	if cycleStart == 0 {
		return activeOverageWarningResolution{
			Stage:      activeOverageWarningStage0,
			CycleStart: now,
		}
	}
	if now-cycleStart >= storageWarningActiveOverageDeletionDelay {
		finalReminderSentAt := history[storageWarningActiveOverage89TemplateID]
		if storageWarningTemplateSentInCycle(history, storageWarningActiveOverage89TemplateID, cycleStart) &&
			finalReminderSentAt >= now-storageWarningPreviousStageFreshnessWindow {
			return activeOverageWarningResolution{
				Stage:      activeOverageWarningStageScheduledDeletion,
				CycleStart: cycleStart,
			}
		}
		return activeOverageWarningResolution{
			Stage:      activeOverageWarningStage0,
			CycleStart: now,
		}
	}
	if now >= cycleStart+storageWarningActiveOverageWarning30Delay &&
		!storageWarningTemplateSentInCycle(history, storageWarningActiveOverage30TemplateID, cycleStart) {
		return activeOverageWarningResolution{
			Stage:      activeOverageWarningStage30,
			CycleStart: cycleStart,
		}
	}
	if now >= cycleStart+storageWarningActiveOverageWarning60Delay &&
		!storageWarningTemplateSentInCycle(history, storageWarningActiveOverage60TemplateID, cycleStart) {
		return activeOverageWarningResolution{
			Stage:      activeOverageWarningStage60,
			CycleStart: cycleStart,
		}
	}
	if now >= cycleStart+storageWarningActiveOverageWarning89Delay &&
		!storageWarningTemplateSentInCycle(history, storageWarningActiveOverage89TemplateID, cycleStart) {
		return activeOverageWarningResolution{
			Stage:      activeOverageWarningStage89,
			CycleStart: cycleStart,
		}
	}
	return activeOverageWarningResolution{
		Stage:      activeOverageWarningStageNone,
		CycleStart: cycleStart,
	}
}

func activeOverageWarningAutoDeleteDate(cycleStart int64, stage activeOverageWarningStage, now int64) int64 {
	if cycleStart <= 0 {
		cycleStart = now
	}
	autoDeleteDate := cycleStart + storageWarningActiveOverageDeletionDelay
	if stage == activeOverageWarningStage89 && autoDeleteDate <= now {
		return now + storageWarningOneDayInMicroseconds
	}
	return autoDeleteDate
}
