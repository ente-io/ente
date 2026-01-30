package llmchat

import (
	"database/sql"
)

func sanitizeCreatedAt(createdAt *int64) sql.NullInt64 {
	if createdAt == nil || *createdAt <= 0 {
		return sql.NullInt64{}
	}

	return sql.NullInt64{Int64: *createdAt, Valid: true}
}
