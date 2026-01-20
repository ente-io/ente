package llmchat

import (
	"context"
	"database/sql"

	"github.com/ente-io/stacktrace"
)

type AttachmentReference struct {
	UserID       int64
	AttachmentID string
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
