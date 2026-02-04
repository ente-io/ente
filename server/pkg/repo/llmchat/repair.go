package llmchat

import (
	"context"
	"database/sql"
	"errors"

	model "github.com/ente-io/museum/ente/llmchat"
	"github.com/ente-io/stacktrace"
	"github.com/google/uuid"
)

func (r *Repository) RepairZeroUUIDs(ctx context.Context, userID int64) error {
	if _, err := r.replaceZeroSessionUUID(ctx, userID); err != nil {
		return err
	}
	if err := r.replaceZeroMessageUUID(ctx, userID); err != nil {
		return err
	}
	return nil
}

func (r *Repository) replaceZeroSessionUUID(ctx context.Context, userID int64) (string, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT encrypted_data, header, client_metadata, is_deleted, created_at, updated_at
		FROM llmchat_sessions
		WHERE session_uuid = $1 AND user_id = $2`,
		model.ZeroUUID,
		userID,
	)

	var encryptedData sql.NullString
	var header sql.NullString
	var clientMetadata sql.NullString
	var isDeleted bool
	var createdAt int64
	var updatedAt int64
	if err := row.Scan(
		&encryptedData,
		&header,
		&clientMetadata,
		&isDeleted,
		&createdAt,
		&updatedAt,
	); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return "", nil
		}
		return "", stacktrace.Propagate(err, "failed to fetch zero-uuid llmchat session")
	}

	newSessionUUID := uuid.NewString()

	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return "", stacktrace.Propagate(err, "failed to begin zero-uuid llmchat session repair")
	}
	rollback := func(cause error) (string, error) {
		_ = tx.Rollback()
		return "", cause
	}

	if _, err := tx.ExecContext(ctx, `UPDATE llmchat_sessions
		SET client_metadata = NULL
		WHERE session_uuid = $1 AND user_id = $2`,
		model.ZeroUUID,
		userID,
	); err != nil {
		return rollback(stacktrace.Propagate(err, "failed to clear zero-uuid session client metadata"))
	}

	if _, err := tx.ExecContext(ctx, `INSERT INTO llmchat_sessions (
		session_uuid,
		user_id,
		encrypted_data,
		header,
		client_metadata,
		is_deleted,
		created_at,
		updated_at
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
		newSessionUUID,
		userID,
		encryptedData,
		header,
		clientMetadata,
		isDeleted,
		createdAt,
		updatedAt,
	); err != nil {
		return rollback(stacktrace.Propagate(err, "failed to insert repaired llmchat session"))
	}

	if _, err := tx.ExecContext(ctx, `UPDATE llmchat_messages
		SET session_uuid = $1
		WHERE session_uuid = $2 AND user_id = $3`,
		newSessionUUID,
		model.ZeroUUID,
		userID,
	); err != nil {
		return rollback(stacktrace.Propagate(err, "failed to re-link llmchat messages to repaired session"))
	}

	if _, err := tx.ExecContext(ctx, `DELETE FROM llmchat_sessions
		WHERE session_uuid = $1 AND user_id = $2`,
		model.ZeroUUID,
		userID,
	); err != nil {
		return rollback(stacktrace.Propagate(err, "failed to delete zero-uuid llmchat session"))
	}

	if err := tx.Commit(); err != nil {
		return "", stacktrace.Propagate(err, "failed to commit zero-uuid llmchat session repair")
	}

	return newSessionUUID, nil
}

func (r *Repository) replaceZeroMessageUUID(ctx context.Context, userID int64) error {
	row := r.DB.QueryRowContext(ctx, `SELECT session_uuid, parent_message_uuid, sender, encrypted_data, header, client_metadata, is_deleted, created_at, updated_at
		FROM llmchat_messages
		WHERE message_uuid = $1 AND user_id = $2`,
		model.ZeroUUID,
		userID,
	)

	var sessionUUID string
	var parentMessageUUID sql.NullString
	var sender string
	var encryptedData sql.NullString
	var header sql.NullString
	var clientMetadata sql.NullString
	var isDeleted bool
	var createdAt int64
	var updatedAt int64
	if err := row.Scan(
		&sessionUUID,
		&parentMessageUUID,
		&sender,
		&encryptedData,
		&header,
		&clientMetadata,
		&isDeleted,
		&createdAt,
		&updatedAt,
	); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil
		}
		return stacktrace.Propagate(err, "failed to fetch zero-uuid llmchat message")
	}

	newMessageUUID := uuid.NewString()
	if parentMessageUUID.Valid && parentMessageUUID.String == model.ZeroUUID {
		parentMessageUUID = sql.NullString{}
	}

	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return stacktrace.Propagate(err, "failed to begin zero-uuid llmchat message repair")
	}
	rollback := func(cause error) error {
		_ = tx.Rollback()
		return cause
	}

	if _, err := tx.ExecContext(ctx, `UPDATE llmchat_messages
		SET client_metadata = NULL
		WHERE message_uuid = $1 AND user_id = $2`,
		model.ZeroUUID,
		userID,
	); err != nil {
		return rollback(stacktrace.Propagate(err, "failed to clear zero-uuid message client metadata"))
	}

	if _, err := tx.ExecContext(ctx, `INSERT INTO llmchat_messages (
		message_uuid,
		user_id,
		session_uuid,
		parent_message_uuid,
		sender,
		encrypted_data,
		header,
		client_metadata,
		is_deleted,
		created_at,
		updated_at
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
		newMessageUUID,
		userID,
		sessionUUID,
		parentMessageUUID,
		sender,
		encryptedData,
		header,
		clientMetadata,
		isDeleted,
		createdAt,
		updatedAt,
	); err != nil {
		return rollback(stacktrace.Propagate(err, "failed to insert repaired llmchat message"))
	}

	if _, err := tx.ExecContext(ctx, `UPDATE llmchat_attachments
		SET message_uuid = $1
		WHERE message_uuid = $2 AND user_id = $3`,
		newMessageUUID,
		model.ZeroUUID,
		userID,
	); err != nil {
		return rollback(stacktrace.Propagate(err, "failed to re-link llmchat attachments to repaired message"))
	}

	if _, err := tx.ExecContext(ctx, `UPDATE llmchat_messages
		SET parent_message_uuid = NULL
		WHERE parent_message_uuid = $1 AND user_id = $2`,
		model.ZeroUUID,
		userID,
	); err != nil {
		return rollback(stacktrace.Propagate(err, "failed to clear zero-uuid parent message references"))
	}

	if _, err := tx.ExecContext(ctx, `DELETE FROM llmchat_messages
		WHERE message_uuid = $1 AND user_id = $2`,
		model.ZeroUUID,
		userID,
	); err != nil {
		return rollback(stacktrace.Propagate(err, "failed to delete zero-uuid llmchat message"))
	}

	if err := tx.Commit(); err != nil {
		return stacktrace.Propagate(err, "failed to commit zero-uuid llmchat message repair")
	}

	return nil
}
