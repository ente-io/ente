package llmchat

import (
	"context"
	"database/sql"
	"errors"

	"github.com/ente-io/museum/ente"
	model "github.com/ente-io/museum/ente/llmchat"
	"github.com/ente-io/stacktrace"
	"github.com/lib/pq"
	"github.com/sirupsen/logrus"
)

func (r *Repository) UpsertMessage(ctx context.Context, userID int64, req model.UpsertMessageRequest) (model.Message, error) {
	if _, err := ParseClientID(req.ClientMetadata); err != nil {
		return model.Message{}, err
	}

	mergedClientMetadata, err := MergeEncryptedData(req.ClientMetadata, req.EncryptedData)
	if err != nil {
		return model.Message{}, err
	}

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
		header,
		client_metadata,
		is_deleted,
		created_at
	) VALUES ($1, $2, $3, $4, $5, $6, $7, FALSE, now_utc_micro_seconds())
	ON CONFLICT (message_uuid) DO UPDATE
		SET session_uuid = EXCLUDED.session_uuid,
			parent_message_uuid = EXCLUDED.parent_message_uuid,
			sender = EXCLUDED.sender,
			header = EXCLUDED.header,
			client_metadata = EXCLUDED.client_metadata,
			is_deleted = FALSE
		WHERE llmchat_messages.user_id = EXCLUDED.user_id
	RETURNING message_uuid, user_id, session_uuid, parent_message_uuid, sender, header, client_metadata, is_deleted, created_at, updated_at`,
		req.MessageUUID,
		userID,
		req.SessionUUID,
		req.ParentMessageUUID,
		req.Sender,
		req.Header,
		mergedClientMetadata,
	)

	var result model.Message
	var parentMessageUUID sql.NullString
	var header sql.NullString
	var clientMetadata sql.NullString
	if err := row.Scan(
		&result.MessageUUID,
		&result.UserID,
		&result.SessionUUID,
		&parentMessageUUID,
		&result.Sender,
		&header,
		&clientMetadata,
		&result.IsDeleted,
		&result.CreatedAt,
		&result.UpdatedAt,
	); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return rollback(stacktrace.Propagate(ente.ErrPermissionDenied, "messageUUID belongs to another user"))
		}
		return rollback(stacktrace.Propagate(err, "failed to upsert llmchat message"))
	}

	if req.Attachments != nil {
		if err := r.replaceMessageAttachments(ctx, tx, userID, req.MessageUUID, req.Attachments); err != nil {
			return rollback(stacktrace.Propagate(err, "failed to upsert llmchat message attachments"))
		}
	}

	if err := tx.Commit(); err != nil {
		return model.Message{}, stacktrace.Propagate(err, "failed to commit transaction")
	}

	if parentMessageUUID.Valid {
		result.ParentMessageUUID = &parentMessageUUID.String
	}
	result.EncryptedData = &req.EncryptedData
	if header.Valid {
		result.Header = &header.String
	}
	if clientMetadata.Valid {
		result.ClientMetadata = &clientMetadata.String
	}
	if req.Attachments == nil {
		result.Attachments = []model.AttachmentMeta{}
	} else {
		result.Attachments = req.Attachments
	}
	return result, nil
}

func (r *Repository) replaceMessageAttachments(ctx context.Context, tx *sql.Tx, userID int64, messageUUID string, attachments []model.AttachmentMeta) error {
	type attachmentInput struct {
		meta     model.AttachmentMeta
		clientID string
	}

	inputs := make([]attachmentInput, 0, len(attachments))
	for _, attachment := range attachments {
		owner, err := r.GetAttachmentOwner(ctx, attachment.ID)
		if err != nil {
			return err
		}
		if owner != nil {
			if owner.UserID != userID {
				return stacktrace.Propagate(ente.ErrPermissionDenied, "attachmentId belongs to another user")
			}
			if owner.MessageUUID != messageUUID {
				return stacktrace.Propagate(ente.ErrBadRequest, "attachmentId already used")
			}
		}
		clientID, err := ParseClientID(attachment.ClientMetadata)
		if err != nil {
			return err
		}
		existing, err := r.GetAttachmentByClientID(ctx, userID, clientID)
		if err != nil {
			return err
		}
		if existing != nil && (existing.AttachmentID != attachment.ID || existing.MessageUUID != messageUUID) {
			if _, err := tx.ExecContext(ctx, `DELETE FROM llmchat_attachments
				WHERE user_id = $1 AND client_metadata IS NOT NULL
					AND client_metadata::jsonb->>'clientId' = $2`, userID, clientID); err != nil {
				return stacktrace.Propagate(err, "failed to clear duplicate attachment clientId")
			}
		}
		inputs = append(inputs, attachmentInput{meta: attachment, clientID: clientID})
	}

	if _, err := tx.ExecContext(ctx, `DELETE FROM llmchat_attachments WHERE user_id = $1 AND message_uuid = $2`, userID, messageUUID); err != nil {
		return stacktrace.Propagate(err, "failed to clear llmchat attachments")
	}
	if len(inputs) == 0 {
		return nil
	}
	for _, input := range inputs {
		attachment := input.meta
		bucketID := llmChatAttachmentBucketID
		if attachment.BucketID != nil && *attachment.BucketID != "" {
			bucketID = *attachment.BucketID
		}
		if _, err := tx.ExecContext(ctx, `INSERT INTO llmchat_attachments(
			attachment_id,
			user_id,
			message_uuid,
			size,
			client_metadata,
			bucket_id
		) VALUES ($1, $2, $3, $4, $5, $6)`, attachment.ID, userID, messageUUID, attachment.Size, attachment.ClientMetadata, bucketID); err != nil {
			return stacktrace.Propagate(err, "failed to insert llmchat attachment")
		}
		objectKey := buildAttachmentObjectKey(userID, attachment.ID)
		if _, err := tx.ExecContext(ctx, `DELETE FROM temp_objects WHERE object_key = $1`, objectKey); err != nil {
			return stacktrace.Propagate(err, "failed to remove llmchat temp object")
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
	result.Attachments = []model.AttachmentMeta{}
	return result, nil
}

func (r *Repository) GetMessageUUIDByClientID(ctx context.Context, userID int64, clientID string) (string, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT message_uuid
		FROM llmchat_messages
		WHERE user_id = $1 AND client_metadata IS NOT NULL
			AND client_metadata::jsonb->>'clientId' = $2`,
		userID,
		clientID,
	)
	var messageUUID string
	if err := row.Scan(&messageUUID); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return "", nil
		}
		return "", stacktrace.Propagate(err, "failed to fetch llmchat message by client id")
	}
	return messageUUID, nil
}

func (r *Repository) GetMessageAttachments(ctx context.Context, userID int64, messageUUID string) ([]model.AttachmentMeta, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT attachment_id, size, client_metadata, bucket_id
		FROM llmchat_attachments
		WHERE user_id = $1 AND message_uuid = $2
		ORDER BY id`,
		userID,
		messageUUID,
	)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to query llmchat message attachments")
	}
	defer rows.Close()

	attachments := make([]model.AttachmentMeta, 0)
	for rows.Next() {
		var attachment model.AttachmentMeta
		var clientMetadata sql.NullString
		var bucketID sql.NullString
		if err := rows.Scan(&attachment.ID, &attachment.Size, &clientMetadata, &bucketID); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan llmchat message attachments")
		}
		if clientMetadata.Valid {
			attachment.ClientMetadata = &clientMetadata.String
		}
		if bucketID.Valid {
			attachment.BucketID = &bucketID.String
		}
		attachments = append(attachments, attachment)
	}
	if err := rows.Err(); err != nil {
		return nil, stacktrace.Propagate(err, "failed to iterate llmchat message attachments")
	}

	return attachments, nil
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
	rows, err := r.DB.QueryContext(ctx, `SELECT a.attachment_id, a.size, a.client_metadata, a.bucket_id
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
		var clientMetadata sql.NullString
		var bucketID sql.NullString
		if err := rows.Scan(&attachment.ID, &attachment.Size, &clientMetadata, &bucketID); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan llmchat session message attachments")
		}
		if clientMetadata.Valid {
			attachment.ClientMetadata = &clientMetadata.String
		}
		if bucketID.Valid {
			attachment.BucketID = &bucketID.String
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
			header = NULL,
			client_metadata = NULL
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

	if _, err := tx.ExecContext(ctx, `DELETE FROM llmchat_attachments a
		USING llmchat_messages m
		WHERE a.user_id = $1 AND m.user_id = $1 AND m.session_uuid = $2
			AND a.message_uuid = m.message_uuid`, userID, sessionUUID); err != nil {
		return rollback(stacktrace.Propagate(err, "failed to delete llmchat session message attachments"))
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

	deleteAttachments := func() error {
		_, err := tx.ExecContext(ctx, `DELETE FROM llmchat_attachments
			WHERE user_id = $1 AND message_uuid = $2`, userID, messageUUID)
		return err
	}

	row := tx.QueryRowContext(ctx, `UPDATE llmchat_messages
		SET is_deleted = TRUE,
			header = NULL,
			client_metadata = NULL
		WHERE message_uuid = $1 AND user_id = $2 AND is_deleted = FALSE
		RETURNING message_uuid, updated_at`,
		messageUUID,
		userID,
	)

	err = row.Scan(&result.MessageUUID, &result.DeletedAt)
	if err == nil {
		if err := deleteAttachments(); err != nil {
			return rollback(stacktrace.Propagate(err, "failed to delete llmchat message attachments"))
		}
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
			if err := deleteAttachments(); err != nil {
				return rollback(stacktrace.Propagate(err, "failed to delete llmchat message attachments"))
			}
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
	rows, err := r.DB.QueryContext(ctx, `SELECT message_uuid,
		session_uuid,
		parent_message_uuid,
		sender,
		client_metadata::jsonb->>'encryptedData' AS encrypted_data,
		header,
		client_metadata,
		created_at,
		updated_at
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

func (r *Repository) GetMessageDiff(ctx context.Context, userID int64, sinceTime int64, limit int16) ([]model.MessageDiffEntry, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT message_uuid,
		session_uuid,
		parent_message_uuid,
		sender,
		client_metadata::jsonb->>'encryptedData' AS encrypted_data,
		header,
		client_metadata,
		created_at,
		updated_at
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
		var encryptedData sql.NullString
		var header sql.NullString
		var clientMetadata sql.NullString
		if err := rows.Scan(
			&entry.MessageUUID,
			&entry.SessionUUID,
			&parentMessageUUID,
			&entry.Sender,
			&encryptedData,
			&header,
			&clientMetadata,
			&entry.CreatedAt,
			&entry.UpdatedAt,
		); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan llmchat message diff")
		}
		if parentMessageUUID.Valid {
			entry.ParentMessageUUID = &parentMessageUUID.String
		}
		if encryptedData.Valid {
			entry.EncryptedData = encryptedData.String
		}
		if header.Valid {
			entry.Header = header.String
		}
		if clientMetadata.Valid {
			entry.ClientMetadata = &clientMetadata.String
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

	messageUUIDs := make([]string, 0, len(entries))
	index := make(map[string]int, len(entries))
	for i := range entries {
		entries[i].Attachments = []model.AttachmentMeta{}
		messageUUIDs = append(messageUUIDs, entries[i].MessageUUID)
		index[entries[i].MessageUUID] = i
	}

	rows, err := r.DB.QueryContext(ctx, `SELECT message_uuid, attachment_id, size, client_metadata, bucket_id
		FROM llmchat_attachments
		WHERE user_id = $1 AND message_uuid = ANY($2::uuid[])
		ORDER BY id`,
		userID,
		pq.Array(messageUUIDs),
	)
	if err != nil {
		return stacktrace.Propagate(err, "failed to query llmchat message diff attachments")
	}
	defer rows.Close()

	for rows.Next() {
		var messageUUID string
		var attachment model.AttachmentMeta
		var clientMetadata sql.NullString
		var bucketID sql.NullString
		if err := rows.Scan(&messageUUID, &attachment.ID, &attachment.Size, &clientMetadata, &bucketID); err != nil {
			return stacktrace.Propagate(err, "failed to scan llmchat message diff attachments")
		}
		if clientMetadata.Valid {
			attachment.ClientMetadata = &clientMetadata.String
		}
		if bucketID.Valid {
			attachment.BucketID = &bucketID.String
		}
		if idx, ok := index[messageUUID]; ok {
			entries[idx].Attachments = append(entries[idx].Attachments, attachment)
		}
	}
	if err := rows.Err(); err != nil {
		return stacktrace.Propagate(err, "failed to iterate llmchat message diff attachments")
	}
	return nil
}
