package userentity

import (
	"context"

	model "github.com/ente-io/museum/ente/userentity"
	"github.com/ente-io/stacktrace"
)

func (r *Repository) CreateKey(ctx context.Context, userID int64, entry model.EntityKeyRequest) error {
	_, err := r.DB.ExecContext(ctx, `INSERT into entity_key(
                         user_id, type, encrypted_key, header) VALUES ($1,$2,$3, $4)`,
		userID, entry.Type, entry.EncryptedKey, entry.Header)

	if err != nil {
		return stacktrace.Propagate(err, "Failed to createTotpEntry")
	}
	return nil
}

func (r *Repository) GetKey(ctx context.Context, userID int64, eType model.EntityType) (model.EntityKey, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT user_id, type, encrypted_key, header,
	 created_at from entity_key where user_id = $1 and type = $2`, userID, eType)
	var result model.EntityKey
	err := row.Scan(&result.UserID, &result.Type, &result.EncryptedKey, &result.Header, &result.CreatedAt)
	if err != nil {
		return result, stacktrace.Propagate(err, "failed to entity key")
	}
	return result, nil
}
