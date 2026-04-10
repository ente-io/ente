package userentity

import (
	"context"

	"github.com/ente-io/museum/ente"
	model "github.com/ente-io/museum/ente/userentity"
	"github.com/ente-io/stacktrace"
)

func (r *Repository) CreateKey(ctx context.Context, userID int64, entry model.EntityKeyRequest) error {
	result, err := r.DB.ExecContext(ctx, `INSERT into entity_key(
                         user_id, type, encrypted_key, header) VALUES ($1,$2,$3, $4)
                         ON CONFLICT (user_id, type) DO NOTHING`,
		userID, entry.Type, entry.EncryptedKey, entry.Header)

	if err != nil {
		return stacktrace.Propagate(err, "Failed to createTotpEntry")
	}
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return stacktrace.Propagate(err, "failed to read affected rows")
	}
	if rowsAffected == 1 {
		return nil
	}

	existing, err := r.GetKey(ctx, userID, entry.Type)
	if err != nil {
		return stacktrace.Propagate(err, "failed to fetch existing key after duplicate create")
	}
	if existing.EncryptedKey == entry.EncryptedKey && existing.Header == entry.Header {
		return nil
	}
	return ente.NewAlreadyExistsError("Key already exists")
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
