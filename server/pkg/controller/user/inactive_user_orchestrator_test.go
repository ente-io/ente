package user

import "testing"

func TestNextInactivityEmailStage(t *testing.T) {
	day := int64(24 * 60 * 60 * 1000 * 1000)
	now := int64(500 * day)
	lastActivity := now - inactiveUserWarn11MonthsInMicroSeconds

	tests := []struct {
		name         string
		lastActivity int64
		now          int64
		history      map[string]int64
		want         inactivityEmailStage
	}{
		{
			name:         "no stage before threshold",
			lastActivity: now - inactiveUserWarn11MonthsInMicroSeconds + day,
			now:          now,
			history:      map[string]int64{},
			want:         inactivityEmailStageNone,
		},
		{
			name:         "first stage at 11 months",
			lastActivity: lastActivity,
			now:          now,
			history:      map[string]int64{},
			want:         inactivityEmailStageWarn11m,
		},
		{
			name:         "second stage waits for replay gap",
			lastActivity: lastActivity,
			now:          now + inactiveUserGap11mTo12mMinus7d - day,
			history: map[string]int64{
				InactiveUserDeletionWarn11mTemplateID: now,
			},
			want: inactivityEmailStageNone,
		},
		{
			name:         "second stage after replay gap",
			lastActivity: lastActivity,
			now:          now + inactiveUserGap11mTo12mMinus7d,
			history: map[string]int64{
				InactiveUserDeletionWarn11mTemplateID: now,
			},
			want: inactivityEmailStageWarn12m7d,
		},
		{
			name:         "third stage after second stage gap",
			lastActivity: lastActivity,
			now:          now + inactiveUserGap12mMinus7dTo1d,
			history: map[string]int64{
				InactiveUserDeletionWarn11mTemplateID:   now - 100,
				InactiveUserDeletionWarn12m7dTemplateID: now,
			},
			want: inactivityEmailStageWarn12m1d,
		},
		{
			name:         "final stage after third stage gap",
			lastActivity: lastActivity,
			now:          now + inactiveUserGap12mMinus1dTo12m,
			history: map[string]int64{
				InactiveUserDeletionWarn11mTemplateID:   now - 100,
				InactiveUserDeletionWarn12m7dTemplateID: now - 50,
				InactiveUserDeletionWarn12m1dTemplateID: now,
			},
			want: inactivityEmailStageFinal,
		},
		{
			name:         "stop after final stage in same cycle",
			lastActivity: lastActivity,
			now:          now + (10 * day),
			history: map[string]int64{
				InactiveUserDeletionWarn11mTemplateID: now - 1000,
				InactiveUserDeletionFinalTemplateID:   now - 100,
			},
			want: inactivityEmailStageNone,
		},
		{
			name:         "activity reset starts new cycle",
			lastActivity: now - inactiveUserWarn11MonthsInMicroSeconds,
			now:          now,
			history: map[string]int64{
				InactiveUserDeletionWarn11mTemplateID: now - inactiveUserWarn11MonthsInMicroSeconds - day,
			},
			want: inactivityEmailStageWarn11m,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := nextInactivityEmailStage(tc.lastActivity, tc.now, tc.history)
			if got != tc.want {
				t.Fatalf("unexpected stage: got %q want %q", got, tc.want)
			}
		})
	}
}
