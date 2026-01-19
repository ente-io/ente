package llmchat

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"

	"github.com/ente-io/museum/ente"
	model "github.com/ente-io/museum/ente/llmchat"
	"github.com/ente-io/stacktrace"
	"github.com/sirupsen/logrus"
)

func (r *Repository) UpsertMessage(ctx context.Context, userID int64, req model.UpsertMessageRequest) (model.Message, error) {
	attachments := req.Attachments
	if attachments == nil {
		attachments = []model.AttachmentMeta{}
	}
	attachmentsJSON, err := json.Marshal(attachments)
	if err != nil {
		return model.Message{}, stacktrace.Propagate(err, "failed to marshal attachments")
	}

	createdAt := sanitizeCreatedAt(req.CreatedAt)

	row := r.DB.QueryRowContext(ctx, `INSERT INTO llmchat_messages(
		message_uuid,
		user_id,
		session_uuid,
		parent_message_uuid,
		sender,
		attachments,
		encrypted_data,
		header,
		is_deleted,
		created_at
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, FALSE, COALESCE($9, now_utc_micro_seconds()))
	ON CONFLICT (message_uuid) DO UPDATE
		SET session_uuid = EXCLUDED.session_uuid,
			parent_message_uuid = EXCLUDED.parent_message_uuid,
			sender = EXCLUDED.sender,
			attachments = EXCLUDED.attachments,
			encrypted_data = EXCLUDED.encrypted_data,
			header = EXCLUDED.header,
			is_deleted = FALSE
		WHERE llmchat_messages.user_id = EXCLUDED.user_id
	RETURNING message_uuid, user_id, session_uuid, parent_message_uuid, sender, attachments, encrypted_data, header, is_deleted, created_at, updated_at`,
		req.MessageUUID,
		userID,
		req.SessionUUID,
		req.ParentMessageUUID,
		req.Sender,
		attachmentsJSON,
		req.EncryptedData,
		req.Header,
		createdAt,
	)

	var result model.Message
	var parentMessageUUID sql.NullString
	var encryptedData sql.NullString
	var header sql.NullString
	var attachmentData []byte
	if err := row.Scan(
		&result.MessageUUID,
		&result.UserID,
		&result.SessionUUID,
		&parentMessageUUID,
		&result.Sender,
		&attachmentData,
		&encryptedData,
		&header,
		&result.IsDeleted,
		&result.CreatedAt,
		&result.UpdatedAt,
	); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return result, stacktrace.Propagate(&ente.ErrNotFoundError, "llmchat message not found")
		}
		return result, stacktrace.Propagate(err, "failed to upsert llmchat message")
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
	parsedAttachments, err := unmarshalAttachments(attachmentData)
	if err != nil {
		return result, stacktrace.Propagate(err, "failed to unmarshal attachments")
	}
	result.Attachments = parsedAttachments
	return result, nil
}

type MessageMeta struct {
	IsDeleted   bool
	Attachments []model.AttachmentMeta
}

func (r *Repository) GetMessageMeta(ctx context.Context, userID int64, messageUUID string) (MessageMeta, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT is_deleted, attachments
		FROM llmchat_messages
		WHERE message_uuid = $1 AND user_id = $2`,
		messageUUID,
		userID,
	)
	var result MessageMeta
	var attachmentData []byte
	if err := row.Scan(&result.IsDeleted, &attachmentData); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return result, stacktrace.Propagate(&ente.ErrNotFoundError, "llmchat message not found")
		}
		return result, stacktrace.Propagate(err, "failed to fetch llmchat message")
	}
	attachments, err := unmarshalAttachments(attachmentData)
	if err != nil {
		return result, stacktrace.Propagate(err, "failed to unmarshal attachments")
	}
	result.Attachments = attachments
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
	rows, err := r.DB.QueryContext(ctx, `SELECT attachments
		FROM llmchat_messages
		WHERE user_id = $1 AND session_uuid = $2 AND is_deleted = FALSE`,
		userID,
		sessionUUID,
	)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to query llmchat session message attachments")
	}
	defer rows.Close()

	result := make([]model.AttachmentMeta, 0)
	for rows.Next() {
		var attachmentData []byte
		if err := rows.Scan(&attachmentData); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan llmchat session message attachments")
		}
		attachments, err := unmarshalAttachments(attachmentData)
		if err != nil {
			return nil, stacktrace.Propagate(err, "failed to unmarshal attachments")
		}
		result = append(result, attachments...)
	}
	if err := rows.Err(); err != nil {
		return nil, stacktrace.Propagate(err, "failed to iterate llmchat session message attachments")
	}
	return result, nil
}

func (r *Repository) SoftDeleteMessagesForSession(ctx context.Context, userID int64, sessionUUID string) (int64, error) {
	res, err := r.DB.ExecContext(ctx, `UPDATE llmchat_messages
		SET is_deleted = TRUE,
			attachments = '[]'::jsonb,
			encrypted_data = NULL,
			header = NULL
		WHERE user_id = $1 AND session_uuid = $2 AND is_deleted = FALSE`,
		userID,
		sessionUUID,
	)
	if err != nil {
		return 0, stacktrace.Propagate(err, "failed to delete llmchat session messages")
	}
	affected, err := res.RowsAffected()
	if err != nil {
		return 0, stacktrace.Propagate(err, "failed to count deleted llmchat session messages")
	}
	return affected, nil
}

func (r *Repository) HasActiveAttachmentReference(ctx context.Context, userID int64, attachmentID string) (bool, error) {
	refJSON, err := json.Marshal([]map[string]string{{"id": attachmentID}})
	if err != nil {
		return false, stacktrace.Propagate(err, "failed to marshal attachment reference")
	}
	row := r.DB.QueryRowContext(ctx, `SELECT EXISTS(
		SELECT 1 FROM llmchat_messages
		WHERE user_id = $1 AND is_deleted = FALSE AND attachments @> $2::jsonb
	)`,
		userID,
		string(refJSON),
	)
	var exists bool
	if err := row.Scan(&exists); err != nil {
		return false, stacktrace.Propagate(err, "failed to check llmchat attachment reference")
	}
	return exists, nil
}

func (r *Repository) DeleteMessage(ctx context.Context, userID int64, messageUUID string) (model.MessageTombstone, error) {
	row := r.DB.QueryRowContext(ctx, `UPDATE llmchat_messages
		SET is_deleted = TRUE,
			attachments = '[]'::jsonb,
			encrypted_data = NULL,
			header = NULL
		WHERE message_uuid = $1 AND user_id = $2 AND is_deleted = FALSE
		RETURNING message_uuid, updated_at`,
		messageUUID,
		userID,
	)

	var result model.MessageTombstone
	err := row.Scan(&result.MessageUUID, &result.DeletedAt)
	if err == nil {
		return result, nil
	}
	if errors.Is(err, sql.ErrNoRows) {
		row = r.DB.QueryRowContext(ctx, `SELECT message_uuid, updated_at
			FROM llmchat_messages
			WHERE message_uuid = $1 AND user_id = $2 AND is_deleted = TRUE`,
			messageUUID,
			userID,
		)
		err = row.Scan(&result.MessageUUID, &result.DeletedAt)
		if err == nil {
			return result, nil
		}
		if errors.Is(err, sql.ErrNoRows) {
			return result, stacktrace.Propagate(&ente.ErrNotFoundError, "llmchat message not found")
		}
		return result, stacktrace.Propagate(err, "failed to fetch deleted llmchat message")
	}
	return result, stacktrace.Propagate(err, "failed to delete llmchat message")
}

func (r *Repository) GetMessageDiffPage(ctx context.Context, userID int64, sinceTime int64, sinceMessageUUID string, limit int16) ([]model.MessageDiffEntry, bool, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT message_uuid, session_uuid, parent_message_uuid, sender, attachments, encrypted_data, header, created_at, updated_at
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

func (r *Repository) GetMessageDiff(ctx context.Context, userID int64, sinceTime int64, limit int16) ([]model.MessageDiffEntry, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT message_uuid, session_uuid, parent_message_uuid, sender, attachments, encrypted_data, header, created_at, updated_at
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
	return convertRowsToMessageDiffEntries(rows)
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
		var attachmentData []byte
		if err := rows.Scan(
			&entry.MessageUUID,
			&entry.SessionUUID,
			&parentMessageUUID,
			&entry.Sender,
			&attachmentData,
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
		attachments, err := unmarshalAttachments(attachmentData)
		if err != nil {
			return nil, stacktrace.Propagate(err, "failed to unmarshal attachments")
		}
		entry.Attachments = attachments
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

func unmarshalAttachments(data []byte) ([]model.AttachmentMeta, error) {
	if len(data) == 0 {
		return []model.AttachmentMeta{}, nil
	}
	var attachments []model.AttachmentMeta
	if err := json.Unmarshal(data, &attachments); err != nil {
		return nil, err
	}
	if attachments == nil {
		return []model.AttachmentMeta{}, nil
	}
	return attachments, nil
}
