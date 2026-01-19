package llmchat

import (
	"context"
	"database/sql"
	"errors"

	"github.com/ente-io/museum/ente"
	model "github.com/ente-io/museum/ente/llmchat"
	"github.com/ente-io/stacktrace"
)

func (r *Repository) UpsertKey(ctx context.Context, userID int64, req model.UpsertKeyRequest) (model.Key, error) {
	row := r.DB.QueryRowContext(ctx, `INSERT INTO llmchat_key(
		user_id,
		encrypted_key,
		header
	) VALUES ($1, $2, $3)
	ON CONFLICT (user_id) DO UPDATE
		SET encrypted_key = EXCLUDED.encrypted_key,
			header = EXCLUDED.header,
			updated_at = now_utc_micro_seconds()
	RETURNING user_id, encrypted_key, header, created_at, updated_at`,
		userID,
		req.EncryptedKey,
		req.Header,
	)

	var result model.Key
	err := row.Scan(&result.UserID, &result.EncryptedKey, &result.Header, &result.CreatedAt, &result.UpdatedAt)
	if err != nil {
		return result, stacktrace.Propagate(err, "failed to upsert llmchat key")
	}
	return result, nil
}

func (r *Repository) GetKey(ctx context.Context, userID int64) (model.Key, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT user_id, encrypted_key, header, created_at, updated_at
		FROM llmchat_key WHERE user_id = $1`, userID)
	var result model.Key
	err := row.Scan(&result.UserID, &result.EncryptedKey, &result.Header, &result.CreatedAt, &result.UpdatedAt)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return result, stacktrace.Propagate(&ente.ErrNotFoundError, "llmchat key is not present")
		}
		return result, stacktrace.Propagate(err, "failed to fetch llmchat key")
	}
	return result, nil
}
