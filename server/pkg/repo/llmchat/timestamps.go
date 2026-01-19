package llmchat

import (
	"database/sql"
	"time"
)

const (
	maxCreatedAtPastSkew   = 90 * 24 * time.Hour
	maxCreatedAtFutureSkew = 5 * time.Minute
)

func sanitizeCreatedAt(createdAt *int64) sql.NullInt64 {
	if createdAt == nil || *createdAt <= 0 {
		return sql.NullInt64{}
	}

	now := time.Now().UnixMicro()
	pastLimit := now - int64(maxCreatedAtPastSkew/time.Microsecond)
	futureLimit := now + int64(maxCreatedAtFutureSkew/time.Microsecond)

	if *createdAt < pastLimit || *createdAt > futureLimit {
		return sql.NullInt64{}
	}

	return sql.NullInt64{Int64: *createdAt, Valid: true}
}
