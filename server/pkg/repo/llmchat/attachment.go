package llmchat

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/ente-io/stacktrace"
)

const llmChatAttachmentPrefix = "llmchat/attachments"

type AttachmentReference struct {
	UserID       int64
	AttachmentID string
}

type AttachmentClientRef struct {
	AttachmentID string
	MessageUUID  string
}

func buildAttachmentObjectKey(userID int64, attachmentID string) string {
	return fmt.Sprintf("%s/%d/%s", llmChatAttachmentPrefix, userID, attachmentID)
}

func (r *Repository) GetAttachmentByClientID(ctx context.Context, userID int64, clientID string) (*AttachmentClientRef, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT attachment_id, message_uuid
		FROM llmchat_attachments
		WHERE user_id = $1 AND client_id = $2`,
		userID,
		clientID,
	)
	var ref AttachmentClientRef
	if err := row.Scan(&ref.AttachmentID, &ref.MessageUUID); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, stacktrace.Propagate(err, "failed to fetch llmchat attachment by client id")
	}
	return &ref, nil
}

func (r *Repository) GetActiveAttachmentUsage(ctx context.Context, userID int64) (int64, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT COALESCE(SUM(a.size), 0)
		FROM llmchat_attachments a
		JOIN llmchat_messages m ON m.message_uuid = a.message_uuid AND m.user_id = a.user_id
		WHERE a.user_id = $1 AND m.is_deleted = FALSE`,
		userID,
	)
	var usage int64
	if err := row.Scan(&usage); err != nil {
		if err == sql.ErrNoRows {
			return 0, nil
		}
		return 0, stacktrace.Propagate(err, "failed to fetch llmchat attachment usage")
	}
	return usage, nil
}

func (r *Repository) GetActiveMessageAttachmentUsage(ctx context.Context, userID int64, messageUUID string) (int64, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT COALESCE(SUM(a.size), 0)
		FROM llmchat_attachments a
		JOIN llmchat_messages m ON m.message_uuid = a.message_uuid AND m.user_id = a.user_id
		WHERE a.user_id = $1 AND m.message_uuid = $2 AND m.is_deleted = FALSE`,
		userID,
		messageUUID,
	)
	var usage int64
	if err := row.Scan(&usage); err != nil {
		if err == sql.ErrNoRows {
			return 0, nil
		}
		return 0, stacktrace.Propagate(err, "failed to fetch llmchat message attachment usage")
	}
	return usage, nil
}

func (r *Repository) DeleteAttachmentRecords(ctx context.Context, userID int64, attachmentID string) error {
	_, err := r.DB.ExecContext(ctx, `DELETE FROM llmchat_attachments WHERE user_id = $1 AND attachment_id = $2::uuid`, userID, attachmentID)
	return stacktrace.Propagate(err, "failed to delete llmchat attachment records")
}

func (r *Repository) GetDeletedAttachmentCandidates(ctx context.Context, limit int) ([]AttachmentReference, error) {
	if limit <= 0 {
		limit = 1000
	}
	rows, err := r.DB.QueryContext(ctx, `SELECT DISTINCT a.user_id, a.attachment_id
		FROM llmchat_attachments a
		JOIN llmchat_messages m ON m.message_uuid = a.message_uuid AND m.user_id = a.user_id
		WHERE m.is_deleted = TRUE
		ORDER BY a.user_id, a.attachment_id
		LIMIT $1`,
		limit,
	)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to query deleted llmchat attachments")
	}
	defer rows.Close()

	refs := make([]AttachmentReference, 0)
	for rows.Next() {
		var ref AttachmentReference
		if err := rows.Scan(&ref.UserID, &ref.AttachmentID); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan deleted llmchat attachments")
		}
		refs = append(refs, ref)
	}
	if err := rows.Err(); err != nil {
		return nil, stacktrace.Propagate(err, "failed to iterate deleted llmchat attachments")
	}
	return refs, nil
}
