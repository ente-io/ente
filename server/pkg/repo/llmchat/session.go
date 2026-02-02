package llmchat

import (
	"context"
	"database/sql"
	"errors"

	"github.com/ente-io/museum/ente"
	model "github.com/ente-io/museum/ente/llmchat"
	"github.com/ente-io/stacktrace"
	"github.com/sirupsen/logrus"
)

func (r *Repository) UpsertSession(ctx context.Context, userID int64, req model.UpsertSessionRequest) (model.Session, error) {
	clientID, err := ParseClientID(req.ClientMetadata)
	if err != nil {
		return model.Session{}, err
	}

	rootSessionUUID := req.RootSessionUUID
	if rootSessionUUID == "" {
		rootSessionUUID = req.SessionUUID
	}

	var branchFromMessageUUID sql.NullString
	if req.BranchFromMessageUUID != nil {
		branchFromMessageUUID = sql.NullString{String: *req.BranchFromMessageUUID, Valid: true}
	}

	row := r.DB.QueryRowContext(ctx, `INSERT INTO llmchat_sessions(
		session_uuid,
		user_id,
		root_session_uuid,
		branch_from_message_uuid,
		encrypted_data,
		header,
		client_metadata,
		client_id,
		is_deleted,
		created_at
	) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, FALSE, now_utc_micro_seconds())
	ON CONFLICT (session_uuid) DO UPDATE
		SET root_session_uuid = EXCLUDED.root_session_uuid,
			branch_from_message_uuid = EXCLUDED.branch_from_message_uuid,
			encrypted_data = EXCLUDED.encrypted_data,
			header = EXCLUDED.header,
			client_metadata = EXCLUDED.client_metadata,
			client_id = EXCLUDED.client_id,
			is_deleted = FALSE
		WHERE llmchat_sessions.user_id = EXCLUDED.user_id
	RETURNING session_uuid, user_id, root_session_uuid, branch_from_message_uuid, encrypted_data, header, client_metadata, is_deleted, created_at, updated_at`,
		req.SessionUUID,
		userID,
		rootSessionUUID,
		branchFromMessageUUID,
		req.EncryptedData,
		req.Header,
		req.ClientMetadata,
		clientID,
	)

	var result model.Session
	var encryptedData sql.NullString
	var header sql.NullString
	var clientMetadata sql.NullString
	var scannedBranch sql.NullString
	if err := row.Scan(
		&result.SessionUUID,
		&result.UserID,
		&result.RootSessionUUID,
		&scannedBranch,
		&encryptedData,
		&header,
		&clientMetadata,
		&result.IsDeleted,
		&result.CreatedAt,
		&result.UpdatedAt,
	); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return result, stacktrace.Propagate(&ente.ErrNotFoundError, "llmchat session not found")
		}
		return result, stacktrace.Propagate(err, "failed to upsert llmchat session")
	}
	if scannedBranch.Valid {
		result.BranchFromMessageUUID = &scannedBranch.String
	}
	if encryptedData.Valid {
		result.EncryptedData = &encryptedData.String
	}
	if header.Valid {
		result.Header = &header.String
	}
	if clientMetadata.Valid {
		result.ClientMetadata = &clientMetadata.String
	}
	return result, nil
}

type SessionMeta struct {
	UserID    int64
	IsDeleted bool
}

func (r *Repository) GetSessionMeta(ctx context.Context, sessionUUID string) (SessionMeta, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT user_id, is_deleted
		FROM llmchat_sessions
		WHERE session_uuid = $1`,
		sessionUUID,
	)
	var meta SessionMeta
	if err := row.Scan(&meta.UserID, &meta.IsDeleted); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return meta, stacktrace.Propagate(&ente.ErrNotFoundError, "llmchat session not found")
		}
		return meta, stacktrace.Propagate(err, "failed to fetch llmchat session")
	}
	return meta, nil
}

func (r *Repository) GetSessionUUIDByClientID(ctx context.Context, userID int64, clientID string) (string, error) {
	row := r.DB.QueryRowContext(ctx, `SELECT session_uuid
		FROM llmchat_sessions
		WHERE user_id = $1 AND client_id = $2`,
		userID,
		clientID,
	)
	var sessionUUID string
	if err := row.Scan(&sessionUUID); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return "", nil
		}
		return "", stacktrace.Propagate(err, "failed to fetch llmchat session by client id")
	}
	return sessionUUID, nil
}

func (r *Repository) DeleteSession(ctx context.Context, userID int64, sessionUUID string) (model.SessionTombstone, error) {
	row := r.DB.QueryRowContext(ctx, `UPDATE llmchat_sessions
		SET is_deleted = TRUE,
			encrypted_data = NULL,
			header = NULL,
			client_metadata = NULL
		WHERE session_uuid = $1 AND user_id = $2 AND is_deleted = FALSE
		RETURNING session_uuid, updated_at`,
		sessionUUID,
		userID,
	)

	var result model.SessionTombstone
	err := row.Scan(&result.SessionUUID, &result.DeletedAt)
	if err == nil {
		return result, nil
	}
	if errors.Is(err, sql.ErrNoRows) {
		row = r.DB.QueryRowContext(ctx, `SELECT session_uuid, updated_at
			FROM llmchat_sessions
			WHERE session_uuid = $1 AND user_id = $2 AND is_deleted = TRUE`,
			sessionUUID,
			userID,
		)
		err = row.Scan(&result.SessionUUID, &result.DeletedAt)
		if err == nil {
			return result, nil
		}
		if errors.Is(err, sql.ErrNoRows) {
			return result, stacktrace.Propagate(&ente.ErrNotFoundError, "llmchat session not found")
		}
		return result, stacktrace.Propagate(err, "failed to fetch deleted llmchat session")
	}
	return result, stacktrace.Propagate(err, "failed to delete llmchat session")
}

func (r *Repository) GetSessionDiffPage(ctx context.Context, userID int64, sinceTime int64, sinceSessionUUID string, limit int16) ([]model.SessionDiffEntry, bool, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT session_uuid, root_session_uuid, branch_from_message_uuid, encrypted_data, header, client_metadata, created_at, updated_at
		FROM llmchat_sessions
		WHERE user_id = $1 AND is_deleted = FALSE AND (updated_at > $2 OR (updated_at = $2 AND session_uuid > $3::uuid))
		ORDER BY updated_at, session_uuid
		LIMIT $4`,
		userID,
		sinceTime,
		sinceSessionUUID,
		limit+1,
	)
	if err != nil {
		return nil, false, stacktrace.Propagate(err, "failed to query llmchat session diff")
	}
	entries, err := convertRowsToSessionDiffEntries(rows)
	if err != nil {
		return nil, false, err
	}
	hasMore := len(entries) > int(limit)
	if hasMore {
		entries = entries[:limit]
	}
	return entries, hasMore, nil
}

func (r *Repository) GetSessionTombstonesPage(ctx context.Context, userID int64, sinceTime int64, sinceSessionUUID string, limit int16) ([]model.SessionTombstone, bool, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT session_uuid, updated_at
		FROM llmchat_sessions
		WHERE user_id = $1 AND is_deleted = TRUE AND (updated_at > $2 OR (updated_at = $2 AND session_uuid > $3::uuid))
		ORDER BY updated_at, session_uuid
		LIMIT $4`,
		userID,
		sinceTime,
		sinceSessionUUID,
		limit+1,
	)
	if err != nil {
		return nil, false, stacktrace.Propagate(err, "failed to query llmchat session tombstones")
	}
	entries, err := convertRowsToSessionTombstones(rows)
	if err != nil {
		return nil, false, err
	}
	hasMore := len(entries) > int(limit)
	if hasMore {
		entries = entries[:limit]
	}
	return entries, hasMore, nil
}

func (r *Repository) GetSessionDiff(ctx context.Context, userID int64, sinceTime int64, limit int16) ([]model.SessionDiffEntry, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT session_uuid, root_session_uuid, branch_from_message_uuid, encrypted_data, header, client_metadata, created_at, updated_at
		FROM llmchat_sessions
		WHERE user_id = $1 AND is_deleted = FALSE AND updated_at > $2
		ORDER BY updated_at, session_uuid
		LIMIT $3`,
		userID,
		sinceTime,
		limit,
	)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to query llmchat session diff")
	}
	return convertRowsToSessionDiffEntries(rows)
}

func (r *Repository) GetSessionTombstones(ctx context.Context, userID int64, sinceTime int64, limit int16) ([]model.SessionTombstone, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT session_uuid, updated_at
		FROM llmchat_sessions
		WHERE user_id = $1 AND is_deleted = TRUE AND updated_at > $2
		ORDER BY updated_at, session_uuid
		LIMIT $3`,
		userID,
		sinceTime,
		limit,
	)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to query llmchat session tombstones")
	}
	return convertRowsToSessionTombstones(rows)
}

func convertRowsToSessionDiffEntries(rows *sql.Rows) ([]model.SessionDiffEntry, error) {
	defer func() {
		if err := rows.Close(); err != nil {
			logrus.Error(err)
		}
	}()

	entries := make([]model.SessionDiffEntry, 0)
	for rows.Next() {
		var entry model.SessionDiffEntry
		var branchFromMessageUUID sql.NullString
		var clientMetadata sql.NullString
		if err := rows.Scan(
			&entry.SessionUUID,
			&entry.RootSessionUUID,
			&branchFromMessageUUID,
			&entry.EncryptedData,
			&entry.Header,
			&clientMetadata,
			&entry.CreatedAt,
			&entry.UpdatedAt,
		); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan llmchat session diff")
		}
		if branchFromMessageUUID.Valid {
			entry.BranchFromMessageUUID = &branchFromMessageUUID.String
		}
		if clientMetadata.Valid {
			entry.ClientMetadata = &clientMetadata.String
		}
		entries = append(entries, entry)
	}
	if err := rows.Err(); err != nil {
		return nil, stacktrace.Propagate(err, "failed to iterate llmchat session diff")
	}
	return entries, nil
}

func convertRowsToSessionTombstones(rows *sql.Rows) ([]model.SessionTombstone, error) {
	defer func() {
		if err := rows.Close(); err != nil {
			logrus.Error(err)
		}
	}()

	tombstones := make([]model.SessionTombstone, 0)
	for rows.Next() {
		var entry model.SessionTombstone
		if err := rows.Scan(&entry.SessionUUID, &entry.DeletedAt); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan llmchat session tombstone")
		}
		tombstones = append(tombstones, entry)
	}
	if err := rows.Err(); err != nil {
		return nil, stacktrace.Propagate(err, "failed to iterate llmchat session tombstones")
	}
	return tombstones, nil
}
