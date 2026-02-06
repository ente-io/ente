package llmchat

import (
	"context"

	"github.com/ente-io/stacktrace"
)

const TombstoneRetentionDays = 90

func (r *Repository) DeleteTombstonesBefore(ctx context.Context, cutoff int64) (int64, int64, error) {
	messageResult, err := r.DB.ExecContext(
		ctx,
		`DELETE FROM llmchat_messages WHERE is_deleted = TRUE AND updated_at < $1`,
		cutoff,
	)
	if err != nil {
		return 0, 0, stacktrace.Propagate(err, "failed to cleanup llmchat message tombstones")
	}
	messageCount, err := messageResult.RowsAffected()
	if err != nil {
		return 0, 0, stacktrace.Propagate(err, "failed to count cleaned llmchat message tombstones")
	}

	sessionResult, err := r.DB.ExecContext(
		ctx,
		`DELETE FROM llmchat_sessions WHERE is_deleted = TRUE AND updated_at < $1`,
		cutoff,
	)
	if err != nil {
		return 0, 0, stacktrace.Propagate(err, "failed to cleanup llmchat session tombstones")
	}
	sessionCount, err := sessionResult.RowsAffected()
	if err != nil {
		return 0, messageCount, stacktrace.Propagate(err, "failed to count cleaned llmchat session tombstones")
	}

	return sessionCount, messageCount, nil
}
