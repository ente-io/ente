package email

import (
	"strings"
	"testing"

	"github.com/ente-io/museum/ente"
	bonus "github.com/ente-io/museum/ente/storagebonus"
	"github.com/ente-io/museum/pkg/utils/billing"
	"github.com/ente-io/museum/pkg/utils/rollout"
	"github.com/ente-io/museum/pkg/utils/time"
	log "github.com/sirupsen/logrus"
	logtest "github.com/sirupsen/logrus/hooks/test"
)

func TestBucketStorageWarningActiveOverage(t *testing.T) {
	now := int64(100)
	effectiveExpiry := now + 10
	expiredWarningAnchor := now + 20
	allottedStorage := int64(50)
	totalUsage := allottedStorage + storageWarningOverageThreshold + 1

	got := bucketStorageWarning(totalUsage, allottedStorage, effectiveExpiry, expiredWarningAnchor, now)
	if got != storageWarningBucketActiveOverage {
		t.Fatalf("unexpected bucket: got %q want %q", got, storageWarningBucketActiveOverage)
	}
}

func TestBucketStorageWarningExpired(t *testing.T) {
	effectiveExpiry := int64(90)
	expiredWarningAnchor := int64(100)
	now := expiredWarningAnchor
	allottedStorage := int64(0)
	totalUsage := allottedStorage + storageWarningOverageThreshold + 1

	got := bucketStorageWarning(totalUsage, allottedStorage, effectiveExpiry, expiredWarningAnchor, now)
	if got != storageWarningBucketExpired {
		t.Fatalf("unexpected bucket: got %q want %q", got, storageWarningBucketExpired)
	}
}

func TestBucketStorageWarningWaitsForExpiredWarningAnchor(t *testing.T) {
	effectiveExpiry := int64(100)
	expiredWarningAnchor := effectiveExpiry + storageWarningExpiredAnchorDelay
	now := effectiveExpiry

	got := bucketStorageWarning(storageWarningOverageThreshold+1, 0, effectiveExpiry, expiredWarningAnchor, now)
	if got != storageWarningBucketNone {
		t.Fatalf("unexpected bucket: got %q want %q", got, storageWarningBucketNone)
	}
}

func TestBucketStorageWarningExpiredRequiresUsageAboveThreshold(t *testing.T) {
	effectiveExpiry := int64(100)
	expiredWarningAnchor := int64(100)
	now := effectiveExpiry

	got := bucketStorageWarning(storageWarningOverageThreshold, 0, effectiveExpiry, expiredWarningAnchor, now)
	if got != storageWarningBucketNone {
		t.Fatalf("unexpected bucket: got %q want %q", got, storageWarningBucketNone)
	}
}

func TestComputeStorageWarningMetricsActiveSubscription(t *testing.T) {
	now := int64(100)
	subscription := &ente.Subscription{
		Storage:         100,
		ExpiryTime:      now + 1,
		PaymentProvider: ente.Stripe,
	}
	totalUsage := subscription.Storage + storageWarningOverageThreshold + 1

	got := computeStorageWarningMetrics(subscription, nil, totalUsage, now)

	if got.BaseStorage != subscription.Storage {
		t.Fatalf("unexpected base storage: got %d want %d", got.BaseStorage, subscription.Storage)
	}
	if got.SubscriptionExpiry != subscription.ExpiryTime {
		t.Fatalf("unexpected subscription expiry: got %d want %d", got.SubscriptionExpiry, subscription.ExpiryTime)
	}
	wantEffectiveExpiry := subscription.ExpiryTime + billing.ProviderToExpiryGracePeriodMap[ente.Stripe]
	if got.EffectiveExpiry != wantEffectiveExpiry {
		t.Fatalf("unexpected effective expiry: got %d want %d", got.EffectiveExpiry, wantEffectiveExpiry)
	}
	wantExpiredWarningAnchor := subscription.ExpiryTime + storageWarningExpiredAnchorDelay
	if got.ExpiredWarningAnchor != wantExpiredWarningAnchor {
		t.Fatalf("unexpected expired warning anchor: got %d want %d", got.ExpiredWarningAnchor, wantExpiredWarningAnchor)
	}
	if got.Bucket != storageWarningBucketActiveOverage {
		t.Fatalf("unexpected bucket: got %q want %q", got.Bucket, storageWarningBucketActiveOverage)
	}
}

func TestComputeStorageWarningMetricsAddonKeepsAccountActive(t *testing.T) {
	now := billing.ProviderToExpiryGracePeriodMap[ente.Stripe] + 1000
	subscription := &ente.Subscription{
		Storage:         100,
		ExpiryTime:      now - billing.ProviderToExpiryGracePeriodMap[ente.Stripe] - 1,
		PaymentProvider: ente.Stripe,
	}
	activeBonuses := &bonus.ActiveStorageBonus{
		StorageBonuses: []bonus.StorageBonus{
			{
				Storage:   10,
				Type:      bonus.AddOnSupport,
				ValidTill: now + time.MicroSecondsInOneHour,
			},
		},
	}
	totalUsage := int64(10) + storageWarningOverageThreshold + 1

	got := computeStorageWarningMetrics(subscription, activeBonuses, totalUsage, now)

	if got.BaseStorage != 0 {
		t.Fatalf("unexpected base storage for expired subscription: got %d want 0", got.BaseStorage)
	}
	if got.SubscriptionExpiry != subscription.ExpiryTime {
		t.Fatalf("unexpected subscription expiry: got %d want %d", got.SubscriptionExpiry, subscription.ExpiryTime)
	}
	if got.EffectiveExpiry != now+time.MicroSecondsInOneHour {
		t.Fatalf("unexpected effective expiry: got %d want %d", got.EffectiveExpiry, now+time.MicroSecondsInOneHour)
	}
	wantExpiredWarningAnchor := subscription.ExpiryTime + storageWarningExpiredAnchorDelay
	if got.ExpiredWarningAnchor != wantExpiredWarningAnchor {
		t.Fatalf("unexpected expired warning anchor: got %d want %d", got.ExpiredWarningAnchor, wantExpiredWarningAnchor)
	}
	if got.Bucket != storageWarningBucketActiveOverage {
		t.Fatalf("unexpected bucket: got %q want %q", got.Bucket, storageWarningBucketActiveOverage)
	}
}

func TestComputeStorageWarningMetricsNilSubscriptionDoesNotCrash(t *testing.T) {
	now := int64(1000)
	activeBonuses := &bonus.ActiveStorageBonus{
		StorageBonuses: []bonus.StorageBonus{
			{
				Storage:   10,
				Type:      bonus.AddOnSupport,
				ValidTill: now + time.MicroSecondsInOneHour,
			},
		},
	}

	got := computeStorageWarningMetrics(nil, activeBonuses, int64(10)+storageWarningOverageThreshold+1, now)

	if got.BaseStorage != 0 {
		t.Fatalf("unexpected base storage without subscription: got %d want 0", got.BaseStorage)
	}
	if got.SubscriptionExpiry != 0 {
		t.Fatalf("unexpected subscription expiry without subscription: got %d want 0", got.SubscriptionExpiry)
	}
	if got.ExpiredWarningAnchor != 0 {
		t.Fatalf("unexpected expired warning anchor without subscription: got %d want 0", got.ExpiredWarningAnchor)
	}
	if got.Bucket != storageWarningBucketActiveOverage {
		t.Fatalf("unexpected bucket: got %q want %q", got.Bucket, storageWarningBucketActiveOverage)
	}
}

func TestComputeStorageWarningMetricsFreeSubscriptionCanBeActiveOverage(t *testing.T) {
	now := int64(100)
	subscription := &ente.Subscription{
		Storage:         10 * (1 << 30),
		ExpiryTime:      now + time.MicroSecondsInOneHour,
		PaymentProvider: ente.Stripe,
		ProductID:       ente.FreePlanProductID,
	}
	totalUsage := subscription.Storage + storageWarningOverageThreshold + 1

	got := computeStorageWarningMetrics(subscription, nil, totalUsage, now)

	if got.BaseStorage != subscription.Storage {
		t.Fatalf("unexpected base storage: got %d want %d", got.BaseStorage, subscription.Storage)
	}
	if got.SubscriptionExpiry != subscription.ExpiryTime {
		t.Fatalf("unexpected subscription expiry: got %d want %d", got.SubscriptionExpiry, subscription.ExpiryTime)
	}
	if got.Bucket != storageWarningBucketActiveOverage {
		t.Fatalf("unexpected bucket: got %q want %q", got.Bucket, storageWarningBucketActiveOverage)
	}
}

func TestResolveExpiredWarningStage(t *testing.T) {
	expiredWarningAnchor := int64(100)

	tests := []struct {
		name    string
		now     int64
		history map[string]int64
		want    expiredWarningStage
	}{
		{
			name:    "before first reminder",
			now:     expiredWarningAnchor - 1,
			history: map[string]int64{},
			want:    expiredWarningStageNone,
		},
		{
			name:    "first reminder at anchor day",
			now:     expiredWarningAnchor,
			history: map[string]int64{},
			want:    expiredWarningStage30,
		},
		{
			name: "second reminder after first sent",
			now:  expiredWarningAnchor + storageWarningExpiredWarning30Delay,
			history: map[string]int64{
				storageWarningExpired30TemplateID: expiredWarningAnchor,
			},
			want: expiredWarningStage60,
		},
		{
			name: "third reminder after earlier stages sent",
			now:  expiredWarningAnchor + storageWarningExpiredWarning60Delay,
			history: map[string]int64{
				storageWarningExpired30TemplateID: expiredWarningAnchor,
				storageWarningExpired60TemplateID: expiredWarningAnchor + storageWarningExpiredWarning30Delay,
			},
			want: expiredWarningStage90,
		},
		{
			name: "final reminder for long expired user",
			now:  expiredWarningAnchor + storageWarningExpiredWarning119Delay + 10,
			history: map[string]int64{
				storageWarningExpired30TemplateID: expiredWarningAnchor,
				storageWarningExpired60TemplateID: expiredWarningAnchor + storageWarningExpiredWarning30Delay,
				storageWarningExpired90TemplateID: expiredWarningAnchor + storageWarningExpiredWarning60Delay,
			},
			want: expiredWarningStage119,
		},
		{
			name:    "long expired backfill without history starts at first reminder",
			now:     expiredWarningAnchor + storageWarningExpiredWarning119Delay + 10,
			history: map[string]int64{},
			want:    expiredWarningStage30,
		},
		{
			name: "old cycle reminder ignored after renewal",
			now:  expiredWarningAnchor,
			history: map[string]int64{
				storageWarningExpired30TemplateID: expiredWarningAnchor - 1,
			},
			want: expiredWarningStage30,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := resolveExpiredWarningStage(expiredWarningAnchor, tc.now, tc.history)
			if got != tc.want {
				t.Fatalf("unexpected stage: got %q want %q", got, tc.want)
			}
		})
	}
}

func TestExpiredWarningAutoDeleteDateClampsOverdueFinalStage(t *testing.T) {
	now := int64(1000)
	expiredWarningAnchor := now - storageWarningExpiredDeletionDelay - 10

	got := expiredWarningAutoDeleteDate(expiredWarningAnchor, expiredWarningStage119, now)
	want := now + storageWarningOneDayInMicroseconds
	if got != want {
		t.Fatalf("unexpected auto delete date: got %d want %d", got, want)
	}
}

func TestResolveActiveOverageWarningStage(t *testing.T) {
	now := int64(1000)
	firstWarningTime := now - storageWarningActiveOverageWarning89Delay - 10

	tests := []struct {
		name    string
		now     int64
		history map[string]int64
		want    activeOverageWarningStage
	}{
		{
			name:    "first reminder is immediate when no history exists",
			now:     now,
			history: map[string]int64{},
			want:    activeOverageWarningStage0,
		},
		{
			name: "30 day reminder after first send",
			now:  now,
			history: map[string]int64{
				StorageWarningActiveOverageAnchorTemplateID: now - storageWarningActiveOverageWarning30Delay,
			},
			want: activeOverageWarningStage30,
		},
		{
			name: "60 day reminder after earlier stage sent",
			now:  now,
			history: map[string]int64{
				StorageWarningActiveOverageAnchorTemplateID: now - storageWarningActiveOverageWarning60Delay,
				storageWarningActiveOverage30TemplateID:     now - storageWarningActiveOverageWarning30Delay,
			},
			want: activeOverageWarningStage60,
		},
		{
			name: "89 day reminder for long running overusage",
			now:  now,
			history: map[string]int64{
				StorageWarningActiveOverageAnchorTemplateID: firstWarningTime,
				storageWarningActiveOverage30TemplateID:     firstWarningTime + storageWarningActiveOverageWarning30Delay,
				storageWarningActiveOverage60TemplateID:     firstWarningTime + storageWarningActiveOverageWarning60Delay,
			},
			want: activeOverageWarningStage89,
		},
		{
			name: "no reminder when all due stages already sent",
			now:  now,
			history: map[string]int64{
				StorageWarningActiveOverageAnchorTemplateID: now - storageWarningActiveOverageWarning30Delay,
				storageWarningActiveOverage30TemplateID:     now - 1,
			},
			want: activeOverageWarningStageNone,
		},
		{
			name: "stale anchor restarts at day zero",
			now:  now,
			history: map[string]int64{
				StorageWarningActiveOverageAnchorTemplateID: now - storageWarningActiveOverageDeletionDelay,
				storageWarningActiveOverage30TemplateID:     now - storageWarningActiveOverageDeletionDelay + storageWarningActiveOverageWarning30Delay,
			},
			want: activeOverageWarningStage0,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := resolveActiveOverageWarningStage(tc.now, tc.history)
			if got != tc.want {
				t.Fatalf("unexpected stage: got %q want %q", got, tc.want)
			}
		})
	}
}

func TestActiveOverageWarningAutoDeleteDateClampsOverdueFinalStage(t *testing.T) {
	now := storageWarningActiveOverageDeletionDelay + 1000
	cycleStart := now - storageWarningActiveOverageDeletionDelay - 10

	got := activeOverageWarningAutoDeleteDate(cycleStart, activeOverageWarningStage89, now)
	want := now + storageWarningOneDayInMicroseconds
	if got != want {
		t.Fatalf("unexpected auto delete date: got %d want %d", got, want)
	}
}

func TestResolveActiveOverageWarningReturnsCycleStart(t *testing.T) {
	now := int64(1000)
	history := map[string]int64{
		StorageWarningActiveOverageAnchorTemplateID: now - storageWarningActiveOverageWarning30Delay,
	}

	got := resolveActiveOverageWarning(now, history)
	if got.Stage != activeOverageWarningStage30 {
		t.Fatalf("unexpected stage: got %q want %q", got.Stage, activeOverageWarningStage30)
	}
	if got.CycleStart != history[StorageWarningActiveOverageAnchorTemplateID] {
		t.Fatalf("unexpected cycle start: got %d want %d", got.CycleStart, history[StorageWarningActiveOverageAnchorTemplateID])
	}
}

func TestStorageWarningTemplateSentInCycle(t *testing.T) {
	history := map[string]int64{
		storageWarningExpired30TemplateID: 50,
	}

	if storageWarningTemplateSentInCycle(history, storageWarningExpired30TemplateID, 100) {
		t.Fatal("expected prior-cycle send to be ignored")
	}
	if !storageWarningTemplateSentInCycle(history, storageWarningExpired30TemplateID, 50) {
		t.Fatal("expected same-cycle send to be considered")
	}
}

func TestStorageWarningCadenceBroken(t *testing.T) {
	now := int64(100 * time.MicroSecondsInOneHour)

	tests := []struct {
		name       string
		snapshot   storageWarningSnapshot
		wantBroken bool
		wantStage  string
	}{
		{
			name: "initial stages are exempt",
			snapshot: storageWarningSnapshot{
				Bucket:             storageWarningBucketActiveOverage,
				ActiveOverageStage: activeOverageWarningStage0,
				EvaluatedAt:        now,
			},
			wantBroken: false,
		},
		{
			name: "active overage stage 30 requires anchor send",
			snapshot: storageWarningSnapshot{
				Bucket:              storageWarningBucketActiveOverage,
				ActiveOverageStage:  activeOverageWarningStage30,
				EvaluatedAt:         now,
				WarningCycleStart:   now - storageWarningActiveOverageWarning30Delay,
				NotificationHistory: map[string]int64{},
			},
			wantBroken: true,
			wantStage:  string(activeOverageWarningStage0),
		},
		{
			name: "active overage previous stage must be recent",
			snapshot: storageWarningSnapshot{
				Bucket:             storageWarningBucketActiveOverage,
				ActiveOverageStage: activeOverageWarningStage60,
				EvaluatedAt:        now,
				WarningCycleStart:  now - storageWarningActiveOverageWarning60Delay,
				NotificationHistory: map[string]int64{
					StorageWarningActiveOverageAnchorTemplateID: now - storageWarningActiveOverageWarning60Delay,
					storageWarningActiveOverage30TemplateID:     now - storageWarningPreviousStageFreshnessWindow - 1,
				},
			},
			wantBroken: true,
			wantStage:  string(activeOverageWarningStage30),
		},
		{
			name: "expired previous stage from prior cycle is ignored",
			snapshot: storageWarningSnapshot{
				Bucket:            storageWarningBucketExpired,
				ExpiredStage:      expiredWarningStage60,
				EvaluatedAt:       now,
				EffectiveExpiry:   now - storageWarningExpiredWarning30Delay,
				WarningCycleStart: now - storageWarningExpiredWarning30Delay,
				NotificationHistory: map[string]int64{
					storageWarningExpired30TemplateID: now - storageWarningExpiredWarning30Delay - 1,
				},
			},
			wantBroken: true,
			wantStage:  string(expiredWarningStage30),
		},
		{
			name: "same cycle recent previous stage passes",
			snapshot: storageWarningSnapshot{
				Bucket:            storageWarningBucketExpired,
				ExpiredStage:      expiredWarningStage90,
				EvaluatedAt:       now,
				EffectiveExpiry:   now - storageWarningExpiredWarning60Delay,
				WarningCycleStart: now - storageWarningExpiredWarning60Delay,
				NotificationHistory: map[string]int64{
					storageWarningExpired60TemplateID: now - storageWarningOneDayInMicroseconds,
				},
			},
			wantBroken: false,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			broken, alert := storageWarningCadenceBroken(tc.snapshot)
			if broken != tc.wantBroken {
				t.Fatalf("unexpected cadence result: got %v want %v", broken, tc.wantBroken)
			}
			if tc.wantBroken && !strings.Contains(alert, "previous_required_stage="+tc.wantStage) {
				t.Fatalf("expected alert to include previous stage %q, got %q", tc.wantStage, alert)
			}
		})
	}
}

func TestBuildStorageWarningCadenceAlert(t *testing.T) {
	snapshot := storageWarningSnapshot{
		RecipientID:     123,
		Bucket:          storageWarningBucketExpired,
		ExpiredStage:    expiredWarningStage90,
		TotalUsage:      75,
		AllottedStorage: 10,
		EffectiveExpiry: 1,
	}

	got := buildStorageWarningCadenceAlert(snapshot, string(expiredWarningStage60), 0)
	for _, want := range []string{
		"recipient_id=123",
		"bucket=expired",
		"intended_stage=expired_90d",
		"previous_required_stage=expired_60d",
		"previous_sent_time=missing",
		"total_usage=75",
		"allotted_storage=10",
	} {
		if !strings.Contains(got, want) {
			t.Fatalf("expected alert to contain %q, got %q", want, got)
		}
	}
}

func TestStorageWarningNotificationGroup(t *testing.T) {
	if got := storageWarningNotificationGroup(storageWarningBucketActiveOverage); got != storageWarningActiveOverageNotificationGroup {
		t.Fatalf("unexpected active overage notification group: got %q want %q", got, storageWarningActiveOverageNotificationGroup)
	}
	if got := storageWarningNotificationGroup(storageWarningBucketExpired); got != storageWarningExpiredNotificationGroup {
		t.Fatalf("unexpected expired notification group: got %q want %q", got, storageWarningExpiredNotificationGroup)
	}
	if got := storageWarningNotificationGroup(storageWarningBucketNone); got != "" {
		t.Fatalf("unexpected notification group for none bucket: got %q want empty", got)
	}
}

func TestStorageWarningShouldPreserveActiveOverageHistory(t *testing.T) {
	if !storageWarningShouldPreserveActiveOverageHistory(storageWarningSnapshot{CurrentBucket: storageWarningBucketActiveOverage, Bucket: storageWarningBucketNone}) {
		t.Fatal("expected active overage history to be preserved even when no stage is due")
	}
	if storageWarningShouldPreserveActiveOverageHistory(storageWarningSnapshot{CurrentBucket: storageWarningBucketExpired}) {
		t.Fatal("expected expired snapshot to not preserve active overage history")
	}
}

func TestStorageWarningTemplateDetailsExpired(t *testing.T) {
	snapshot := storageWarningSnapshot{
		Bucket:       storageWarningBucketExpired,
		ExpiredStage: expiredWarningStage90,
	}
	templateID, templateName, subject, ok := storageWarningTemplateDetails(snapshot)
	if !ok {
		t.Fatal("expected expired bucket template details")
	}
	if templateID != storageWarningExpired90TemplateID || templateName != storageWarningExpiredTemplate || subject != storageWarningExpired90Subject {
		t.Fatalf("unexpected expired template details: %q %q %q", templateID, templateName, subject)
	}
}

func TestStorageWarningTemplateDetailsActiveOverage(t *testing.T) {
	snapshot := storageWarningSnapshot{
		Bucket:             storageWarningBucketActiveOverage,
		ActiveOverageStage: activeOverageWarningStage60,
	}
	templateID, templateName, subject, ok := storageWarningTemplateDetails(snapshot)
	if !ok {
		t.Fatal("expected active overage template details")
	}
	if templateID != storageWarningActiveOverage60TemplateID || templateName != storageWarningActiveOverageTemplate || subject != storageWarningActiveOverage60Subject {
		t.Fatalf("unexpected active overage template details: %q %q %q", templateID, templateName, subject)
	}
}

func TestProcessStorageWarningSnapshotSkipsDueToRolloutAfterTemplateSelection(t *testing.T) {
	standardLogger := log.StandardLogger()
	originalHooks := standardLogger.ReplaceHooks(make(log.LevelHooks))
	hook := logtest.NewGlobal()
	defer standardLogger.ReplaceHooks(originalHooks)

	snapshot := storageWarningSnapshot{
		RecipientID:      12345,
		AccountEmail:     "user@example.com",
		TotalUsage:       storageWarningOverageThreshold + 10,
		AllottedStorage:  0,
		AvailableStorage: -10,
		Bucket:           storageWarningBucketExpired,
		ExpiredStage:     expiredWarningStage30,
		EffectiveExpiry:  1,
	}

	result, err := (&EmailNotificationController{}).processStorageWarningSnapshot(snapshot)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result != storageWarningProcessResultSkippedRollout {
		t.Fatalf("unexpected result: got %q want %q", result, storageWarningProcessResultSkippedRollout)
	}

	entry := hook.LastEntry()
	if entry == nil {
		t.Fatal("expected rollout skip log entry")
	}
	if entry.Message != "Skipping storage warning email due to rollout" {
		t.Fatalf("unexpected log message: %q", entry.Message)
	}
	if got := entry.Data["template_id"]; got != storageWarningExpired30TemplateID {
		t.Fatalf("unexpected template id in log: got %v want %q", got, storageWarningExpired30TemplateID)
	}
	if got := entry.Data["template_filename"]; got != storageWarningExpiredTemplate {
		t.Fatalf("unexpected template filename in log: got %v want %q", got, storageWarningExpiredTemplate)
	}
	if got := entry.Data["subject"]; got != storageWarningExpired30Subject {
		t.Fatalf("unexpected subject in log: got %v want %q", got, storageWarningExpired30Subject)
	}
	if got := entry.Data["rollout_included"]; got != false {
		t.Fatalf("unexpected rollout flag in log: got %v want false", got)
	}
}

func TestBuildStorageWarningRunSummary(t *testing.T) {
	stats := newStorageWarningRunStats()
	stats.ProcessedUsers = 42
	stats.SentEmails = 3
	stats.SuccessByStage[string(expiredWarningStage30)] = 1
	stats.SuccessByStage[string(activeOverageWarningStage0)] = 2
	stats.FailureByStage[string(activeOverageWarningStage60)] = 1
	stats.PreStageFailures = 4
	stats.SkippedRolloutPct = 39

	got := buildStorageWarningRunSummary(stats, 0)
	want := "Storage warning run summary (1970-01-01T00:00:00Z): processed=42 sent=3 | success={expired_30d=1, expired_60d=0, expired_90d=0, expired_119d=0, active_overage_0d=2, active_overage_30d=0, active_overage_60d=0, active_overage_89d=0} | failures={expired_30d=0, expired_60d=0, expired_90d=0, expired_119d=0, active_overage_0d=0, active_overage_30d=0, active_overage_60d=1, active_overage_89d=0} | pre_stage_failures=4 | skipped_rollout_percentage=39 | rollout_percentage=0"
	if got != want {
		t.Fatalf("unexpected summary:\n got: %s\nwant: %s", got, want)
	}
}

func TestIsInStorageWarningRollout(t *testing.T) {
	const userID int64 = 12345

	if !isInStorageWarningRollout(userID, "alerts@ente.io") {
		t.Fatal("expected @ente.io account to always be in rollout")
	}

	want := rollout.IsInPercentageRollout(userID, storageWarningRolloutNonce, storageWarningRolloutPercentage)
	got := isInStorageWarningRollout(userID, "user@example.com")
	if got != want {
		t.Fatalf("unexpected percentage rollout decision: got %v want %v", got, want)
	}
}
