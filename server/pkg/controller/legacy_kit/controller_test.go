package legacy_kit

import (
	"testing"
	"time"

	"github.com/ente-io/museum/ente"
	legacykitrepo "github.com/ente-io/museum/pkg/repo/legacy_kit"
	timeutil "github.com/ente-io/museum/pkg/utils/time"
	"github.com/google/uuid"
	"github.com/stretchr/testify/require"
)

func TestToRecoverySessionReturnsRemainingWaitTime(t *testing.T) {
	row := &legacykitrepo.RecoverySessionRow{
		ID:        uuid.New(),
		KitID:     uuid.New(),
		Status:    ente.LegacyKitRecoveryStatusWaiting,
		WaitTill:  timeutil.MicrosecondsAfterHours(1),
		CreatedAt: timeutil.Microseconds(),
	}

	session := toRecoverySession(row)

	require.Equal(t, ente.LegacyKitRecoveryStatusWaiting, session.Status)
	require.Greater(t, session.WaitTill, int64(0))
	require.LessOrEqual(t, session.WaitTill, time.Hour.Microseconds())
}

func TestToRecoverySessionMarksExpiredWaitingSessionReady(t *testing.T) {
	row := &legacykitrepo.RecoverySessionRow{
		ID:        uuid.New(),
		KitID:     uuid.New(),
		Status:    ente.LegacyKitRecoveryStatusWaiting,
		WaitTill:  timeutil.Microseconds() - 1,
		CreatedAt: timeutil.Microseconds(),
	}

	session := toRecoverySession(row)

	require.Equal(t, ente.LegacyKitRecoveryStatusReady, session.Status)
	require.Equal(t, int64(0), session.WaitTill)
}
