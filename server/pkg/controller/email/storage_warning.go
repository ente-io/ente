package email

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"
	stdtime "time"

	"github.com/ente-io/museum/ente"
	bonus "github.com/ente-io/museum/ente/storagebonus"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/billing"
	emailUtil "github.com/ente-io/museum/pkg/utils/email"
	"github.com/ente-io/museum/pkg/utils/rollout"
	"github.com/ente-io/museum/pkg/utils/time"
	log "github.com/sirupsen/logrus"
)

const (
	StorageWarningMailLock       = "family_storage_warning_mail_lock"
	FamilyStorageWarningMailLock = StorageWarningMailLock

	storageWarningBaseTemplate = "base.html"
	storageWarningFromName     = "Ente"
	storageWarningFromEmail    = "support@ente.io"

	storageWarningOverageThreshold             = 25 * (1 << 30)
	storageWarningPreviousStageFreshnessWindow = 35 * 24 * time.MicroSecondsInOneHour
	storageWarningOneDayInMicroseconds         = 24 * time.MicroSecondsInOneHour
	storageWarningRolloutPercentage            = 0
	storageWarningRolloutNonce                 = "storage-warning-v1"

	storageWarningActiveOverageNotificationGroup = "storage_warning_active_overage"
	storageWarningExpiredNotificationGroup       = "storage_warning_expired"
)

type storageWarningBucket string

const (
	storageWarningBucketNone          storageWarningBucket = "none"
	storageWarningBucketExpired       storageWarningBucket = "expired"
	storageWarningBucketActiveOverage storageWarningBucket = "active_over_25_gib"
)

type storageWarningSnapshot struct {
	RecipientID         int64
	AccountEmail        string
	TotalUsage          int64
	BaseStorage         int64
	UsableBonus         int64
	AllottedStorage     int64
	AvailableStorage    int64
	EffectiveExpiry     int64
	EvaluatedAt         int64
	CurrentBucket       storageWarningBucket
	Bucket              storageWarningBucket
	ActiveOverageStage  activeOverageWarningStage
	ExpiredStage        expiredWarningStage
	AutoDeleteDate      int64
	IsFamilyPlan        bool
	WarningCycleStart   int64
	NotificationHistory map[string]int64
}

type storageWarningMetrics struct {
	BaseStorage      int64
	UsableBonus      int64
	AllottedStorage  int64
	AvailableStorage int64
	EffectiveExpiry  int64
	Bucket           storageWarningBucket
}

type storageWarningRunStats struct {
	ProcessedUsers    int
	SentEmails        int
	SuccessByStage    map[string]int
	FailureByStage    map[string]int
	PreStageFailures  int
	SkippedRolloutPct int
}

var storageWarningStageOrder = []string{
	string(expiredWarningStage30),
	string(expiredWarningStage60),
	string(expiredWarningStage90),
	string(expiredWarningStage119),
	string(activeOverageWarningStage0),
	string(activeOverageWarningStage30),
	string(activeOverageWarningStage60),
	string(activeOverageWarningStage89),
}

func newStorageWarningRunStats() storageWarningRunStats {
	successByStage := make(map[string]int, len(storageWarningStageOrder))
	failureByStage := make(map[string]int, len(storageWarningStageOrder))
	for _, stage := range storageWarningStageOrder {
		successByStage[stage] = 0
		failureByStage[stage] = 0
	}
	return storageWarningRunStats{
		SuccessByStage: successByStage,
		FailureByStage: failureByStage,
	}
}

func hasAnyStorageWarningStageSuccess(successByStage map[string]int) bool {
	for _, stage := range storageWarningStageOrder {
		if successByStage[stage] > 0 {
			return true
		}
	}
	return false
}

func formatStorageWarningStageCounts(counts map[string]int) string {
	parts := make([]string, 0, len(storageWarningStageOrder))
	for _, stage := range storageWarningStageOrder {
		parts = append(parts, fmt.Sprintf("%s=%d", stage, counts[stage]))
	}
	return strings.Join(parts, ", ")
}

func buildStorageWarningRunSummary(stats storageWarningRunStats, runAt int64) string {
	return fmt.Sprintf(
		"Storage warning run summary (%s): processed=%d sent=%d | success={%s} | failures={%s} | pre_stage_failures=%d | skipped_rollout_percentage=%d | rollout_percentage=%d",
		stdtime.UnixMicro(runAt).UTC().Format(stdtime.RFC3339),
		stats.ProcessedUsers,
		stats.SentEmails,
		formatStorageWarningStageCounts(stats.SuccessByStage),
		formatStorageWarningStageCounts(stats.FailureByStage),
		stats.PreStageFailures,
		stats.SkippedRolloutPct,
		storageWarningRolloutPercentage,
	)
}

func (c *EmailNotificationController) SendStorageWarningMails() {
	if c.UserRepo == nil || c.UsageRepo == nil || c.BillingRepo == nil || c.StorageBonusRepo == nil ||
		c.LockController == nil || c.NotificationHistoryRepo == nil {
		log.Error("Skipping storage warning mails: controller dependencies are not fully configured")
		return
	}

	lockStatus := c.LockController.TryLock(StorageWarningMailLock, time.MicrosecondsAfterHours(24))
	if !lockStatus {
		log.Info("Skipping storage warning mails as another instance is still running")
		return
	}
	defer c.LockController.ReleaseLock(StorageWarningMailLock)

	ctx := context.Background()
	now := time.Microseconds()
	candidates, err := c.UsageRepo.GetStorageWarningCandidates(ctx, storageWarningOverageThreshold)
	if err != nil {
		log.WithError(err).Error("Failed to fetch storage warning candidates")
		return
	}

	processed := 0
	sent := 0
	skipped := 0
	failed := 0
	skippedRolloutPct := 0
	stats := newStorageWarningRunStats()
	sentByBucket := map[storageWarningBucket]int{
		storageWarningBucketExpired:       0,
		storageWarningBucketActiveOverage: 0,
	}
	failedByBucket := map[storageWarningBucket]int{
		storageWarningBucketExpired:       0,
		storageWarningBucketActiveOverage: 0,
	}
	preserveActiveOverageHistoryRecipientIDs := make(map[int64]struct{})

	for _, candidate := range candidates {
		processed++
		stats.ProcessedUsers++
		snapshot, err := c.buildStorageWarningSnapshot(ctx, candidate, now)
		if err != nil {
			failed++
			stats.PreStageFailures++
			preserveActiveOverageHistoryRecipientIDs[candidate.RecipientID] = struct{}{}
			candidateType := "individual"
			if candidate.IsFamilyPlan {
				candidateType = "family"
			}
			log.WithFields(log.Fields{
				"recipient_id":   candidate.RecipientID,
				"candidate_type": candidateType,
			}).WithError(err).Error("Failed to build storage warning snapshot")
			continue
		}
		if storageWarningShouldPreserveActiveOverageHistory(snapshot) {
			preserveActiveOverageHistoryRecipientIDs[snapshot.RecipientID] = struct{}{}
		}
		candidateType := "individual"
		if candidate.IsFamilyPlan {
			candidateType = "family"
		}
		if !isInStorageWarningRollout(snapshot.RecipientID, snapshot.AccountEmail) {
			skippedRolloutPct++
			stats.SkippedRolloutPct++
			log.WithFields(log.Fields{
				"recipient_id":     snapshot.RecipientID,
				"account_email":    snapshot.AccountEmail,
				"candidate_type":   candidateType,
				"rollout_nonce":    storageWarningRolloutNonce,
				"rollout_percent":  storageWarningRolloutPercentage,
				"rollout_reason":   "percentage",
				"is_family_plan":   snapshot.IsFamilyPlan,
				"rollout_included": false,
			}).Info("Skipping storage warning email due to rollout")
			skipped++
			continue
		}
		sentNow, skippedNow, err := c.processStorageWarningSnapshot(snapshot)
		if err != nil {
			failed++
			stage := storageWarningStageKey(snapshot)
			if stage == "" {
				stats.PreStageFailures++
			} else {
				stats.FailureByStage[stage]++
			}
			failedByBucket[snapshot.Bucket]++
			continue
		}
		if skippedNow {
			skipped++
			continue
		}
		if sentNow {
			sent++
			stats.SentEmails++
			if stage := storageWarningStageKey(snapshot); stage != "" {
				stats.SuccessByStage[stage]++
			}
			sentByBucket[snapshot.Bucket]++
		}
	}

	if err := c.cleanupActiveOverageWarningHistory(preserveActiveOverageHistoryRecipientIDs); err != nil {
		log.WithError(err).Error("Failed to clean up active overage notification history")
	}

	log.WithFields(log.Fields{
		"processed":                  processed,
		"sent":                       sent,
		"skipped":                    skipped,
		"failed":                     failed,
		"sent_expired":               sentByBucket[storageWarningBucketExpired],
		"sent_active_overage":        sentByBucket[storageWarningBucketActiveOverage],
		"failed_expired":             failedByBucket[storageWarningBucketExpired],
		"failed_active_overage":      failedByBucket[storageWarningBucketActiveOverage],
		"stage_success":              stats.SuccessByStage,
		"stage_failures":             stats.FailureByStage,
		"pre_stage_failures":         stats.PreStageFailures,
		"skipped_rollout_percentage": skippedRolloutPct,
		"has_stage_movements":        hasAnyStorageWarningStageSuccess(stats.SuccessByStage),
		"rollout_percentage":         storageWarningRolloutPercentage,
		"rollout_nonce":              storageWarningRolloutNonce,
	}).Info("Storage warning mail run completed")

	if c.DiscordController != nil && hasAnyStorageWarningStageSuccess(stats.SuccessByStage) {
		c.DiscordController.NotifyAdminAction(buildStorageWarningRunSummary(stats, now))
	}
}

// Keep the old entrypoint while external schedulers are updated.
func (c *EmailNotificationController) SendFamilyStorageWarningMails() {
	c.SendStorageWarningMails()
}

func (c *EmailNotificationController) cleanupActiveOverageWarningHistory(preserveRecipientIDs map[int64]struct{}) error {
	keepUserIDs := make([]int64, 0, len(preserveRecipientIDs))
	for userID := range preserveRecipientIDs {
		keepUserIDs = append(keepUserIDs, userID)
	}
	return c.NotificationHistoryRepo.DeleteNotificationHistoryByGroupExcludingUsers(storageWarningActiveOverageNotificationGroup, keepUserIDs)
}

func (c *EmailNotificationController) buildStorageWarningSnapshot(ctx context.Context, candidate repo.StorageWarningCandidate, now int64) (storageWarningSnapshot, error) {
	if candidate.IsFamilyPlan {
		return c.buildFamilyStorageWarningSnapshot(ctx, candidate.RecipientID, now)
	}
	return c.buildIndividualStorageWarningSnapshot(ctx, candidate.RecipientID, now)
}

func (c *EmailNotificationController) buildFamilyStorageWarningSnapshot(ctx context.Context, adminID int64, now int64) (storageWarningSnapshot, error) {
	admin, err := c.UserRepo.Get(adminID)
	if err != nil {
		return storageWarningSnapshot{}, err
	}
	if admin.Email == "" {
		return storageWarningSnapshot{}, fmt.Errorf("admin email not available")
	}

	totalUsage, err := c.UsageRepo.StorageForFamilyAdmin(adminID)
	if err != nil {
		return storageWarningSnapshot{}, err
	}

	activeBonuses, err := c.StorageBonusRepo.GetActiveStorageBonuses(ctx, adminID)
	if err != nil {
		return storageWarningSnapshot{}, err
	}

	subscription, err := c.BillingRepo.GetUserSubscription(adminID)
	var sub *ente.Subscription
	if err == nil {
		sub = &subscription
	} else if !errors.Is(err, sql.ErrNoRows) {
		return storageWarningSnapshot{}, err
	}

	metrics := computeStorageWarningMetrics(sub, activeBonuses, totalUsage, now)
	snapshot := storageWarningSnapshot{
		RecipientID:      adminID,
		AccountEmail:     admin.Email,
		TotalUsage:       totalUsage,
		BaseStorage:      metrics.BaseStorage,
		UsableBonus:      metrics.UsableBonus,
		AllottedStorage:  metrics.AllottedStorage,
		AvailableStorage: metrics.AvailableStorage,
		EffectiveExpiry:  metrics.EffectiveExpiry,
		EvaluatedAt:      now,
		CurrentBucket:    metrics.Bucket,
		Bucket:           metrics.Bucket,
		IsFamilyPlan:     true,
	}
	return c.decorateStorageWarningSnapshot(snapshot, now)
}

func (c *EmailNotificationController) buildIndividualStorageWarningSnapshot(ctx context.Context, userID int64, now int64) (storageWarningSnapshot, error) {
	user, err := c.UserRepo.Get(userID)
	if err != nil {
		return storageWarningSnapshot{}, err
	}
	if user.Email == "" {
		return storageWarningSnapshot{}, fmt.Errorf("user email not available")
	}

	totalUsage, err := c.UsageRepo.GetUsage(userID)
	if err != nil {
		return storageWarningSnapshot{}, err
	}

	activeBonuses, err := c.StorageBonusRepo.GetActiveStorageBonuses(ctx, userID)
	if err != nil {
		return storageWarningSnapshot{}, err
	}

	subscription, err := c.BillingRepo.GetUserSubscription(userID)
	var sub *ente.Subscription
	if err == nil {
		sub = &subscription
	} else if !errors.Is(err, sql.ErrNoRows) {
		return storageWarningSnapshot{}, err
	}

	metrics := computeStorageWarningMetrics(sub, activeBonuses, totalUsage, now)
	snapshot := storageWarningSnapshot{
		RecipientID:      userID,
		AccountEmail:     user.Email,
		TotalUsage:       totalUsage,
		BaseStorage:      metrics.BaseStorage,
		UsableBonus:      metrics.UsableBonus,
		AllottedStorage:  metrics.AllottedStorage,
		AvailableStorage: metrics.AvailableStorage,
		EffectiveExpiry:  metrics.EffectiveExpiry,
		EvaluatedAt:      now,
		CurrentBucket:    metrics.Bucket,
		Bucket:           metrics.Bucket,
		IsFamilyPlan:     false,
	}
	return c.decorateStorageWarningSnapshot(snapshot, now)
}

func (c *EmailNotificationController) decorateStorageWarningSnapshot(snapshot storageWarningSnapshot, now int64) (storageWarningSnapshot, error) {
	switch snapshot.Bucket {
	case storageWarningBucketExpired:
		history, err := c.NotificationHistoryRepo.GetLastNotificationTimes(snapshot.RecipientID, expiredWarningTemplateIDs())
		if err != nil {
			return storageWarningSnapshot{}, err
		}
		snapshot.NotificationHistory = history
		snapshot.WarningCycleStart = snapshot.EffectiveExpiry
		snapshot.ExpiredStage = resolveExpiredWarningStage(snapshot.EffectiveExpiry, now, history)
		if snapshot.ExpiredStage == expiredWarningStageNone {
			snapshot.Bucket = storageWarningBucketNone
			return snapshot, nil
		}
		snapshot.AutoDeleteDate = expiredWarningAutoDeleteDate(snapshot.EffectiveExpiry, snapshot.ExpiredStage, now)
	case storageWarningBucketActiveOverage:
		history, err := c.NotificationHistoryRepo.GetLastNotificationTimes(snapshot.RecipientID, activeOverageWarningTemplateIDs())
		if err != nil {
			return storageWarningSnapshot{}, err
		}
		snapshot.NotificationHistory = history
		overageResolution := resolveActiveOverageWarning(now, history)
		snapshot.ActiveOverageStage = overageResolution.Stage
		snapshot.WarningCycleStart = overageResolution.CycleStart
		if snapshot.ActiveOverageStage == activeOverageWarningStageNone {
			snapshot.Bucket = storageWarningBucketNone
			return snapshot, nil
		}
		snapshot.AutoDeleteDate = activeOverageWarningAutoDeleteDate(snapshot.WarningCycleStart, snapshot.ActiveOverageStage, now)
	}
	return snapshot, nil
}

func (c *EmailNotificationController) processStorageWarningSnapshot(snapshot storageWarningSnapshot) (sent bool, skipped bool, err error) {
	logger := log.WithFields(log.Fields{
		"recipient_id":   snapshot.RecipientID,
		"is_family_plan": snapshot.IsFamilyPlan,
	})
	if snapshot.Bucket == storageWarningBucketNone {
		return false, true, nil
	}

	templateID, templateName, subject, ok := storageWarningTemplateDetails(snapshot)
	if !ok {
		logger.WithField("bucket", snapshot.Bucket).Warn("Skipping storage warning due to unknown bucket")
		return false, true, nil
	}

	if storageWarningTemplateSentInCycle(snapshot.NotificationHistory, templateID, snapshot.WarningCycleStart) {
		return false, true, nil
	}
	if cadenceBroken, cadenceAlert := storageWarningCadenceBroken(snapshot); cadenceBroken {
		logger.WithFields(log.Fields{
			"bucket":              snapshot.Bucket,
			"active_stage":        snapshot.ActiveOverageStage,
			"expired_stage":       snapshot.ExpiredStage,
			"warning_cycle_start": snapshot.WarningCycleStart,
		}).Warn("Skipping storage warning due to broken stage cadence")
		if c.DiscordController != nil {
			c.DiscordController.NotifyAdminAction(cadenceAlert)
		}
		return false, true, nil
	}

	templateData := map[string]interface{}{
		"TotalUsage":       snapshot.TotalUsage,
		"AllottedStorage":  snapshot.AllottedStorage,
		"AvailableStorage": snapshot.AvailableStorage,
		"AccountEmail":     snapshot.AccountEmail,
		"ExpiryDate":       formatDate(snapshot.EffectiveExpiry),
		"AutoDeleteDate":   formatDate(snapshot.AutoDeleteDate),
		"IsFamilyPlan":     snapshot.IsFamilyPlan,
	}
	logger = logger.WithFields(log.Fields{
		"bucket":                        snapshot.Bucket,
		"account_email":                 snapshot.AccountEmail,
		"rollout_nonce":                 storageWarningRolloutNonce,
		"rollout_percentage":            storageWarningRolloutPercentage,
		"base_storage":                  snapshot.BaseStorage,
		"usable_bonus":                  snapshot.UsableBonus,
		"total_usage":                   snapshot.TotalUsage,
		"allotted_storage":              snapshot.AllottedStorage,
		"available_storage":             snapshot.AvailableStorage,
		"overage_threshold":             storageWarningOverageThreshold,
		"overage_trigger_limit":         snapshot.AllottedStorage + storageWarningOverageThreshold,
		"usage_above_allotted":          positiveDelta(snapshot.TotalUsage, snapshot.AllottedStorage),
		"usage_above_trigger_limit":     positiveDelta(snapshot.TotalUsage, snapshot.AllottedStorage+storageWarningOverageThreshold),
		"base_storage_gib":              formatStorageGiB(snapshot.BaseStorage),
		"usable_bonus_gib":              formatStorageGiB(snapshot.UsableBonus),
		"total_usage_gib":               formatStorageGiB(snapshot.TotalUsage),
		"allotted_storage_gib":          formatStorageGiB(snapshot.AllottedStorage),
		"available_storage_gib":         formatStorageGiB(snapshot.AvailableStorage),
		"overage_trigger_limit_gib":     formatStorageGiB(snapshot.AllottedStorage + storageWarningOverageThreshold),
		"usage_above_allotted_gib":      formatStorageGiB(positiveDelta(snapshot.TotalUsage, snapshot.AllottedStorage)),
		"usage_above_trigger_limit_gib": formatStorageGiB(positiveDelta(snapshot.TotalUsage, snapshot.AllottedStorage+storageWarningOverageThreshold)),
		"effective_expiry":              snapshot.EffectiveExpiry,
		"warning_cycle_start":           snapshot.WarningCycleStart,
		"active_stage":                  snapshot.ActiveOverageStage,
		"expired_stage":                 snapshot.ExpiredStage,
		"auto_delete_date":              snapshot.AutoDeleteDate,
		"subject":                       subject,
		"template_id":                   templateID,
		"template_filename":             templateName,
	})

	err = emailUtil.SendTemplatedEmailV2(
		[]string{snapshot.AccountEmail},
		storageWarningFromName,
		storageWarningFromEmail,
		subject,
		storageWarningBaseTemplate,
		templateName,
		templateData,
		nil,
	)
	if err != nil {
		logger.WithError(err).Error("Failed to send storage warning email")
		return false, false, err
	}

	if err := c.NotificationHistoryRepo.SetLastNotificationTimeToNowWithGroup(snapshot.RecipientID, templateID, storageWarningNotificationGroup(snapshot.Bucket)); err != nil {
		logger.WithError(err).Error("Failed to persist storage warning history")
		return false, false, err
	}

	logger.Info("Sent storage warning email")
	return true, false, nil
}

func computeStorageWarningMetrics(subscription *ente.Subscription, activeBonuses *bonus.ActiveStorageBonus, totalUsage int64, now int64) storageWarningMetrics {
	baseEffectiveExpiry := int64(0)
	baseStorage := int64(0)
	if subscription != nil {
		baseEffectiveExpiry = effectiveSubscriptionExpiry(*subscription)
		if baseEffectiveExpiry > now {
			baseStorage = subscription.Storage
		}
	}

	effectiveExpiry := baseEffectiveExpiry
	if bonusExpiry := activeBonuses.GetMaxExpiry(); bonusExpiry > effectiveExpiry {
		effectiveExpiry = bonusExpiry
	}

	usableBonus := activeBonuses.GetUsableBonus(baseStorage)
	allottedStorage := baseStorage + usableBonus
	return storageWarningMetrics{
		BaseStorage:      baseStorage,
		UsableBonus:      usableBonus,
		AllottedStorage:  allottedStorage,
		AvailableStorage: allottedStorage - totalUsage,
		EffectiveExpiry:  effectiveExpiry,
		Bucket:           bucketStorageWarning(totalUsage, allottedStorage, effectiveExpiry, now),
	}
}

func effectiveSubscriptionExpiry(subscription ente.Subscription) int64 {
	expiry := subscription.ExpiryTime
	if value, ok := billing.ProviderToExpiryGracePeriodMap[subscription.PaymentProvider]; ok {
		expiry += value
	}
	return expiry
}

func bucketStorageWarning(totalUsage int64, allottedStorage int64, effectiveExpiry int64, now int64) storageWarningBucket {
	if totalUsage <= allottedStorage+storageWarningOverageThreshold {
		return storageWarningBucketNone
	}
	if effectiveExpiry > 0 && effectiveExpiry <= now {
		return storageWarningBucketExpired
	}
	if effectiveExpiry > now && totalUsage > (allottedStorage+storageWarningOverageThreshold) {
		return storageWarningBucketActiveOverage
	}
	return storageWarningBucketNone
}

func storageWarningTemplateDetails(snapshot storageWarningSnapshot) (templateID string, templateName string, subject string, ok bool) {
	switch snapshot.Bucket {
	case storageWarningBucketActiveOverage:
		return activeOverageWarningTemplateDetails(snapshot.ActiveOverageStage)
	case storageWarningBucketExpired:
		return expiredWarningTemplateDetails(snapshot.ExpiredStage)
	default:
		return "", "", "", false
	}
}

func formatDate(microseconds int64) string {
	if microseconds <= 0 {
		return ""
	}
	return stdtime.UnixMicro(microseconds).UTC().Format("January 2, 2006")
}

func formatTimestamp(microseconds int64) string {
	if microseconds <= 0 {
		return "missing"
	}
	return stdtime.UnixMicro(microseconds).UTC().Format(stdtime.RFC3339)
}

func storageWarningCadenceBroken(snapshot storageWarningSnapshot) (bool, string) {
	previousTemplateID, previousStageKey, ok := storageWarningPreviousStage(snapshot)
	if !ok {
		return false, ""
	}

	previousSentAt := snapshot.NotificationHistory[previousTemplateID]
	if !storageWarningTemplateSentInCycle(snapshot.NotificationHistory, previousTemplateID, snapshot.WarningCycleStart) ||
		previousSentAt < snapshot.EvaluatedAt-storageWarningPreviousStageFreshnessWindow {
		return true, buildStorageWarningCadenceAlert(snapshot, previousStageKey, previousSentAt)
	}

	return false, ""
}

func storageWarningPreviousStage(snapshot storageWarningSnapshot) (templateID string, stageKey string, ok bool) {
	switch snapshot.Bucket {
	case storageWarningBucketExpired:
		switch snapshot.ExpiredStage {
		case expiredWarningStage60:
			return storageWarningExpired30TemplateID, string(expiredWarningStage30), true
		case expiredWarningStage90:
			return storageWarningExpired60TemplateID, string(expiredWarningStage60), true
		case expiredWarningStage119:
			return storageWarningExpired90TemplateID, string(expiredWarningStage90), true
		}
	case storageWarningBucketActiveOverage:
		switch snapshot.ActiveOverageStage {
		case activeOverageWarningStage30:
			return StorageWarningActiveOverageAnchorTemplateID, string(activeOverageWarningStage0), true
		case activeOverageWarningStage60:
			return storageWarningActiveOverage30TemplateID, string(activeOverageWarningStage30), true
		case activeOverageWarningStage89:
			return storageWarningActiveOverage60TemplateID, string(activeOverageWarningStage60), true
		}
	}

	return "", "", false
}

func buildStorageWarningCadenceAlert(snapshot storageWarningSnapshot, previousStageKey string, previousSentAt int64) string {
	return fmt.Sprintf(
		"Storage warning cadence broken: recipient_id=%d bucket=%s intended_stage=%s previous_required_stage=%s previous_sent_time=%s total_usage=%d allotted_storage=%d effective_expiry=%s",
		snapshot.RecipientID,
		snapshot.Bucket,
		storageWarningStageKey(snapshot),
		previousStageKey,
		formatTimestamp(previousSentAt),
		snapshot.TotalUsage,
		snapshot.AllottedStorage,
		formatTimestamp(snapshot.EffectiveExpiry),
	)
}

func storageWarningNotificationGroup(bucket storageWarningBucket) string {
	switch bucket {
	case storageWarningBucketActiveOverage:
		return storageWarningActiveOverageNotificationGroup
	case storageWarningBucketExpired:
		return storageWarningExpiredNotificationGroup
	default:
		return ""
	}
}

func storageWarningShouldPreserveActiveOverageHistory(snapshot storageWarningSnapshot) bool {
	return snapshot.CurrentBucket == storageWarningBucketActiveOverage
}

func storageWarningTemplateSentInCycle(history map[string]int64, templateID string, cycleStart int64) bool {
	if len(history) == 0 {
		return false
	}
	sentAt := history[templateID]
	if sentAt <= 0 {
		return false
	}
	if cycleStart <= 0 {
		return true
	}
	return sentAt >= cycleStart
}

func storageWarningStageKey(snapshot storageWarningSnapshot) string {
	switch snapshot.Bucket {
	case storageWarningBucketExpired:
		if snapshot.ExpiredStage == expiredWarningStageNone {
			return ""
		}
		return string(snapshot.ExpiredStage)
	case storageWarningBucketActiveOverage:
		if snapshot.ActiveOverageStage == activeOverageWarningStageNone {
			return ""
		}
		return string(snapshot.ActiveOverageStage)
	default:
		return ""
	}
}

func isEnteDomainStorageWarningAccount(email string) bool {
	return strings.HasSuffix(emailUtil.NormalizeEmail(email), "@ente.io")
}

func isInStorageWarningRollout(userID int64, email string) bool {
	if isEnteDomainStorageWarningAccount(email) {
		return true
	}
	return rollout.IsInPercentageRollout(userID, storageWarningRolloutNonce, storageWarningRolloutPercentage)
}

func positiveDelta(lhs int64, rhs int64) int64 {
	if lhs <= rhs {
		return 0
	}
	return lhs - rhs
}

func formatStorageGiB(bytes int64) string {
	return fmt.Sprintf("%.2fGiB", float64(bytes)/float64(1<<30))
}
