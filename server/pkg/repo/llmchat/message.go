package llmchat

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/ente-io/museum/ente"
	model "github.com/ente-io/museum/ente/llmchat"
	"github.com/ente-io/stacktrace"
	"github.com/lib/pq"
	"github.com/sirupsen/logrus"
)

func (r *Repository) UpsertMessage(ctx context.Context, userID int64, req model.UpsertMessageRequest) (model.Message, error) {
	attachments := req.Attachments
	if attachments == nil {
		attachments = []model.AttachmentMeta{}
	}

	createdAt := sanitizeCreatedAt(req.CreatedAt)

	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return model.Message{}, stacktrace.Propagate(err, "failed to begin transaction")
	}
	rollback := func(cause error) (model.Message, error) {
		_ = tx.Rollback()
		return model.Message{}, cause
	}

	row := tx.QueryRowContext(ctx, `INSERT INTO llmchat_messages(
		message_uuid,
		user_id,
		session_uuid,
		parent_message_uuid,
		sender,
		encrypted_data,
		header,
		is_deleted,
		created_at
	) VALUES ($1, $2, $3, $4, $5, $6, $7, FALSE, COALESCE($8, now_utc_micro_seconds()))
	ON CONFLICT (message_uuid) DO UPDATE
		SET session_uuid = EXCLUDED.session_uuid,
			parent_message_uuid = EXCLUDED.parent_message_uuid,
			sender = EXCLUDED.sender,
			encrypted_data = EXCLUDED.encrypted_data,
			header = EXCLUDED.header,
			is_deleted = FALSE
		WHERE llmchat_messages.user_id = EXCLUDED.user_id
	RETURNING message_uuid, user_id, session_uuid, parent_message_uuid, sender, encrypted_data, header, is_deleted, created_at, updated_at`,
		req.MessageUUID,
		userID,
		req.SessionUUID,
		req.ParentMessageUUID,
		req.Sender,
		req.EncryptedData,
		req.Header,
		createdAt,
	)

	var result model.Message
	var parentMessageUUID sql.NullString
	var encryptedData sql.NullString
	var header sql.NullString
	if err := row.Scan(
		&result.MessageUUID,
		&result.UserID,
		&result.SessionUUID,
		&parentMessageUUID,
		&result.Sender,
		&encryptedData,
		&header,
		&result.IsDeleted,
		&result.CreatedAt,
		&result.UpdatedAt,
	); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return rollback(stacktrace.Propagate(&ente.ErrNotFoundError, "llmchat message not found"))
		}
		return rollback(stacktrace.Propagate(err, "failed to upsert llmchat message"))
	}

	if err := r.replaceMessageAttachments(ctx, tx, userID, req.MessageUUID, attachments); err != nil {
		return rollback(stacktrace.Propagate(err, "failed to persist llmchat attachments"))
	}

	for _, attachment := range attachments {
		objectKey := fmt.Sprintf("llmchat/attachments/%d/%s", userID, attachment.ID)
		if _, err := tx.ExecContext(ctx, `DELETE FROM temp_objects WHERE object_key = $1`, objectKey); err != nil {
			return rollback(stacktrace.Propagate(err, "failed to commit llmchat attachment"))
		}
	}

	if err := tx.Commit(); err != nil {
		return model.Message{}, stacktrace.Propagate(err, "failed to commit transaction")
	}

	if parentMessageUUID.Valid {
		result.ParentMessageUUID = &parentMessageUUID.String
	}
	if encryptedData.Valid {
		result.EncryptedData = &encryptedData.String
	}
	if header.Valid {
		result.Header = &header.String
	}
	result.Attachments = attachments
	return result, nil
}

func (r *Repository) replaceMessageAttachments(ctx context.Context, tx *sql.Tx, userID int64, messageUUID string, attachments []model.AttachmentMeta) error {
	if _, err := tx.ExecContext(ctx, `DELETE FROM llmchat_attachments WHERE user_id = $1 AND message_uuid = $2`, userID, messageUUID); err != nil {
		return stacktrace.Propagate(err, "failed to clear llmchat attachments")
	}
	if len(attachments) == 0 {
		return nil
	}
	for _, attachment := range attachments {
		if _, err := tx.ExecContext(ctx, `INSERT INTO llmchat_attachments(
			attachment_id,
			user_id,
			message_uuid,
			size,
			encrypted_name
		) VALUES ($1, $2, $3, $4, $5)`, attachment.ID, userID, messageUUID, attachment.Size, attachment.EncryptedName); err != nil {
			return stacktrace.Propagate(err, "failed to insert llmchat attachment")
		}
	}
	return nil
}

type MessageMeta struct {
	IsDeleted   bool
	Attachments []model.AttachmentMeta
}

func (r *Repository) GetMessageMeta(ctx context.Context, userID int64, messageUUID string) (MessageMeta, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT is_deleted
		FROM llmchat_messages
		WHERE message_uuid = $1 AND user_id = $2`,
		messageUUID,
		userID,
	)
	var result MessageMeta
	if err := row.Scan(&result.IsDeleted); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return result, stacktrace.Propagate(&ente.ErrNotFoundError, "llmchat message not found")
		}
		return result, stacktrace.Propagate(err, "failed to fetch llmchat message")
	}
	attachments, err := r.getAttachmentsByMessageUUIDs(ctx, userID, []string{messageUUID})
	if err != nil {
		return result, stacktrace.Propagate(err, "failed to fetch llmchat attachments")
	}
	result.Attachments = attachments[messageUUID]
	if result.Attachments == nil {
		result.Attachments = []model.AttachmentMeta{}
	}
	return result, nil
}

func (r *Repository) GetActiveMessageCount(ctx context.Context, userID int64) (int64, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT COUNT(*) FROM llmchat_messages WHERE user_id = $1 AND is_deleted = FALSE`, userID)
	var count int64
	if err := row.Scan(&count); err != nil {
		return 0, stacktrace.Propagate(err, "failed to count llmchat messages")
	}
	return count, nil
}

func (r *Repository) GetActiveSessionMessageAttachments(ctx context.Context, userID int64, sessionUUID string) ([]model.AttachmentMeta, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT a.attachment_id, a.size, a.encrypted_name
		FROM llmchat_attachments a
		JOIN llmchat_messages m ON m.message_uuid = a.message_uuid AND m.user_id = a.user_id
		WHERE a.user_id = $1 AND m.session_uuid = $2 AND m.is_deleted = FALSE
		ORDER BY a.id`,
		userID,
		sessionUUID,
	)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to query llmchat session message attachments")
	}
	defer rows.Close()

	result := make([]model.AttachmentMeta, 0)
	for rows.Next() {
		var attachment model.AttachmentMeta
		if err := rows.Scan(&attachment.ID, &attachment.Size, &attachment.EncryptedName); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan llmchat session message attachments")
		}
		result = append(result, attachment)
	}
	if err := rows.Err(); err != nil {
		return nil, stacktrace.Propagate(err, "failed to iterate llmchat session message attachments")
	}
	return result, nil
}

func (r *Repository) SoftDeleteMessagesForSession(ctx context.Context, userID int64, sessionUUID string) (int64, error) {
	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return 0, stacktrace.Propagate(err, "failed to begin transaction")
	}
	rollback := func(cause error) (int64, error) {
		_ = tx.Rollback()
		return 0, cause
	}

	res, err := tx.ExecContext(ctx, `UPDATE llmchat_messages
		SET is_deleted = TRUE,
			encrypted_data = NULL,
			header = NULL
		WHERE user_id = $1 AND session_uuid = $2 AND is_deleted = FALSE`,
		userID,
		sessionUUID,
	)
	if err != nil {
		return rollback(stacktrace.Propagate(err, "failed to delete llmchat session messages"))
	}

	affected, err := res.RowsAffected()
	if err != nil {
		return rollback(stacktrace.Propagate(err, "failed to count deleted llmchat session messages"))
	}

	if err := tx.Commit(); err != nil {
		return 0, stacktrace.Propagate(err, "failed to commit transaction")
	}
	return affected, nil
}

func (r *Repository) HasActiveAttachmentReference(ctx context.Context, userID int64, attachmentID string) (bool, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT EXISTS(
		SELECT 1
		FROM llmchat_attachments a
		JOIN llmchat_messages m ON m.message_uuid = a.message_uuid AND m.user_id = a.user_id
		WHERE a.user_id = $1 AND a.attachment_id = $2::uuid AND m.is_deleted = FALSE
	)`,
		userID,
		attachmentID,
	)
	var exists bool
	if err := row.Scan(&exists); err != nil {
		return false, stacktrace.Propagate(err, "failed to check llmchat attachment reference")
	}
	return exists, nil
}

func (r *Repository) DeleteMessage(ctx context.Context, userID int64, messageUUID string) (model.MessageTombstone, error) {
	var result model.MessageTombstone

	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return result, stacktrace.Propagate(err, "failed to begin transaction")
	}
	rollback := func(cause error) (model.MessageTombstone, error) {
		_ = tx.Rollback()
		return result, cause
	}

	row := tx.QueryRowContext(ctx, `UPDATE llmchat_messages
		SET is_deleted = TRUE,
			encrypted_data = NULL,
			header = NULL
		WHERE message_uuid = $1 AND user_id = $2 AND is_deleted = FALSE
		RETURNING message_uuid, updated_at`,
		messageUUID,
		userID,
	)

	err = row.Scan(&result.MessageUUID, &result.DeletedAt)
	if err == nil {
		if err := tx.Commit(); err != nil {
			return result, stacktrace.Propagate(err, "failed to commit transaction")
		}
		return result, nil
	}
	if errors.Is(err, sql.ErrNoRows) {
		row = tx.QueryRowContext(ctx, `SELECT message_uuid, updated_at
			FROM llmchat_messages
			WHERE message_uuid = $1 AND user_id = $2 AND is_deleted = TRUE`,
			messageUUID,
			userID,
		)
		err = row.Scan(&result.MessageUUID, &result.DeletedAt)
		if err == nil {
			if err := tx.Commit(); err != nil {
				return result, stacktrace.Propagate(err, "failed to commit transaction")
			}
			return result, nil
		}
		if errors.Is(err, sql.ErrNoRows) {
			return rollback(stacktrace.Propagate(&ente.ErrNotFoundError, "llmchat message not found"))
		}
		return rollback(stacktrace.Propagate(err, "failed to fetch deleted llmchat message"))
	}
	return rollback(stacktrace.Propagate(err, "failed to delete llmchat message"))
}

func (r *Repository) GetMessageDiffPage(ctx context.Context, userID int64, sinceTime int64, sinceMessageUUID string, limit int16) ([]model.MessageDiffEntry, bool, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT message_uuid, session_uuid, parent_message_uuid, sender, encrypted_data, header, created_at, updated_at
		FROM llmchat_messages
		WHERE user_id = $1 AND is_deleted = FALSE AND (updated_at > $2 OR (updated_at = $2 AND message_uuid > $3::uuid))
		ORDER BY updated_at, message_uuid
		LIMIT $4`,
		userID,
		sinceTime,
		sinceMessageUUID,
		limit+1,
	)
	if err != nil {
		return nil, false, stacktrace.Propagate(err, "failed to query llmchat message diff")
	}
	entries, err := convertRowsToMessageDiffEntries(rows)
	if err != nil {
		return nil, false, err
	}
	hasMore := len(entries) > int(limit)
	if hasMore {
		entries = entries[:limit]
	}
	if err := r.populateMessageAttachments(ctx, userID, entries); err != nil {
		return nil, false, err
	}
	return entries, hasMore, nil
}

func (r *Repository) GetMessageTombstonesPage(ctx context.Context, userID int64, sinceTime int64, sinceMessageUUID string, limit int16) ([]model.MessageTombstone, bool, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT message_uuid, updated_at
		FROM llmchat_messages
		WHERE user_id = $1 AND is_deleted = TRUE AND (updated_at > $2 OR (updated_at = $2 AND message_uuid > $3::uuid))
		ORDER BY updated_at, message_uuid
		LIMIT $4`,
		userID,
		sinceTime,
		sinceMessageUUID,
		limit+1,
	)
	if err != nil {
		return nil, false, stacktrace.Propagate(err, "failed to query llmchat message tombstones")
	}
	entries, err := convertRowsToMessageTombstones(rows)
	if err != nil {
		return nil, false, err
	}
	hasMore := len(entries) > int(limit)
	if hasMore {
		entries = entries[:limit]
	}
	return entries, hasMore, nil
}

// GetMessageDiff returns a non-paginated diff; retained for backwards compatibility.
func (r *Repository) GetMessageDiff(ctx context.Context, userID int64, sinceTime int64, limit int16) ([]model.MessageDiffEntry, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT message_uuid, session_uuid, parent_message_uuid, sender, encrypted_data, header, created_at, updated_at
		FROM llmchat_messages
		WHERE user_id = $1 AND is_deleted = FALSE AND updated_at > $2
		ORDER BY updated_at, message_uuid
		LIMIT $3`,
		userID,
		sinceTime,
		limit,
	)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to query llmchat message diff")
	}
	entries, err := convertRowsToMessageDiffEntries(rows)
	if err != nil {
		return nil, err
	}
	if err := r.populateMessageAttachments(ctx, userID, entries); err != nil {
		return nil, err
	}
	return entries, nil
}

func (r *Repository) GetMessageTombstones(ctx context.Context, userID int64, sinceTime int64, limit int16) ([]model.MessageTombstone, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT message_uuid, updated_at
		FROM llmchat_messages
		WHERE user_id = $1 AND is_deleted = TRUE AND updated_at > $2
		ORDER BY updated_at, message_uuid
		LIMIT $3`,
		userID,
		sinceTime,
		limit,
	)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to query llmchat message tombstones")
	}
	return convertRowsToMessageTombstones(rows)
}

func convertRowsToMessageDiffEntries(rows *sql.Rows) ([]model.MessageDiffEntry, error) {
	defer func() {
		if err := rows.Close(); err != nil {
			logrus.Error(err)
		}
	}()

	entries := make([]model.MessageDiffEntry, 0)
	for rows.Next() {
		var entry model.MessageDiffEntry
		var parentMessageUUID sql.NullString
		if err := rows.Scan(
			&entry.MessageUUID,
			&entry.SessionUUID,
			&parentMessageUUID,
			&entry.Sender,
			&entry.EncryptedData,
			&entry.Header,
			&entry.CreatedAt,
			&entry.UpdatedAt,
		); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan llmchat message diff")
		}
		if parentMessageUUID.Valid {
			entry.ParentMessageUUID = &parentMessageUUID.String
		}
		entries = append(entries, entry)
	}
	if err := rows.Err(); err != nil {
		return nil, stacktrace.Propagate(err, "failed to iterate llmchat message diff")
	}
	return entries, nil
}

func convertRowsToMessageTombstones(rows *sql.Rows) ([]model.MessageTombstone, error) {
	defer func() {
		if err := rows.Close(); err != nil {
			logrus.Error(err)
		}
	}()

	tombstones := make([]model.MessageTombstone, 0)
	for rows.Next() {
		var entry model.MessageTombstone
		if err := rows.Scan(&entry.MessageUUID, &entry.DeletedAt); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan llmchat message tombstone")
		}
		tombstones = append(tombstones, entry)
	}
	if err := rows.Err(); err != nil {
		return nil, stacktrace.Propagate(err, "failed to iterate llmchat message tombstones")
	}
	return tombstones, nil
}

func (r *Repository) populateMessageAttachments(ctx context.Context, userID int64, entries []model.MessageDiffEntry) error {
	if len(entries) == 0 {
		return nil
	}
	messageUUIDs := make([]string, len(entries))
	for i, entry := range entries {
		messageUUIDs[i] = entry.MessageUUID
	}
	attachmentsByMessage, err := r.getAttachmentsByMessageUUIDs(ctx, userID, messageUUIDs)
	if err != nil {
		return stacktrace.Propagate(err, "failed to fetch llmchat attachments")
	}
	for i := range entries {
		attachments := attachmentsByMessage[entries[i].MessageUUID]
		if attachments == nil {
			attachments = []model.AttachmentMeta{}
		}
		entries[i].Attachments = attachments
	}
	return nil
}

func (r *Repository) getAttachmentsByMessageUUIDs(ctx context.Context, userID int64, messageUUIDs []string) (map[string][]model.AttachmentMeta, error) {
	result := make(map[string][]model.AttachmentMeta)
	if len(messageUUIDs) == 0 {
		return result, nil
	}
	rows, err := r.DB.QueryContext(ctx, `SELECT message_uuid, attachment_id, size, encrypted_name
		FROM llmchat_attachments
		WHERE user_id = $1 AND message_uuid = ANY($2::uuid[])
		ORDER BY message_uuid, id`,
		userID,
		pq.Array(messageUUIDs),
	)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to query llmchat attachments")
	}
	defer rows.Close()

	for rows.Next() {
		var messageUUID string
		var attachment model.AttachmentMeta
		if err := rows.Scan(&messageUUID, &attachment.ID, &attachment.Size, &attachment.EncryptedName); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan llmchat attachments")
		}
		result[messageUUID] = append(result[messageUUID], attachment)
	}
	if err := rows.Err(); err != nil {
		return nil, stacktrace.Propagate(err, "failed to iterate llmchat attachments")
	}
	return result, nil
}
