package public

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/ente-io/museum/ente/base"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
)

// FileLinkRepository defines the methods for inserting, updating and
// retrieving entities related to public file
type FileLinkRepository struct {
	DB         *sql.DB
	photoHost  string
	lockerHost string
}

// NewFileLinkRepo ..
func NewFileLinkRepo(db *sql.DB, albumHost string, lockerHost string) *FileLinkRepository {
	if albumHost == "" {
		albumHost = "https://albums.ente.io"
	}
	if lockerHost == "" {
		lockerHost = "https://locker.ente.io"
	}
	return &FileLinkRepository{
		DB:        db,
		photoHost: albumHost,
	}
}

func (pcr *FileLinkRepository) PhotoLink(token string) string {
	return fmt.Sprintf("%s/?t=%s", pcr.photoHost, token)
}

func (pcr *FileLinkRepository) LockerFileLink(token string) string {
	return fmt.Sprintf("%s/?t=%s", pcr.lockerHost, token)
}

func (pcr *FileLinkRepository) Insert(
	ctx context.Context,
	fileID int64,
	ownerID int64,
	token string,
) (*string, error) {
	id, err := base.NewID("pft")
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to generate new ID for public file token")
	}
	_, err = pcr.DB.ExecContext(ctx, `INSERT INTO public_file_tokens 
    (id, file_id, owner_id, access_token) VALUES ($1, $2, $3, $4)`,
		id, fileID, ownerID, token)
	if err != nil {
		if err.Error() == "pq: duplicate key value violates unique constraint \"public_access_token_unique_idx\"" {
			return nil, ente.ErrActiveLinkAlreadyExists
		}
		return nil, stacktrace.Propagate(err, "failed to insert")
	}
	return id, nil
}

// GetActiveFileUrlToken will return ente.PublicCollectionToken for given collection ID
// Note: The token could be expired or deviceLimit is already reached
func (pcr *FileLinkRepository) GetActiveFileUrlToken(ctx context.Context, fileID int64) (*ente.PublicFileUrlRow, error) {
	row := pcr.DB.QueryRowContext(ctx, `SELECT id, file_id, owner_id, access_token, valid_till, device_limit, 
       is_disabled, pw_hash, pw_nonce, mem_limit, ops_limit, enable_download FROM 
                                                   public_file_tokens WHERE file_id = $1 and is_disabled = FALSE`,
		fileID)

	ret := ente.PublicFileUrlRow{}
	err := row.Scan(&ret.LinkID, &ret.FileID, ret.OwnerID, &ret.Token, &ret.ValidTill, &ret.DeviceLimit,
		&ret.IsDisabled, &ret.PassHash, &ret.Nonce, &ret.MemLimit, &ret.OpsLimit, &ret.EnableDownload)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &ret, nil
}

func (pcr *FileLinkRepository) GetFileUrlRowByToken(ctx context.Context, accessToken string) (*ente.PublicFileUrlRow, error) {
	row := pcr.DB.QueryRowContext(ctx,
		`SELECT id, file_id, owner_id, is_disabled, valid_till, device_limit, enable_download, pw_hash, pw_nonce, mem_limit, ops_limit
       created_at, updated_at
		from public_file_tokens 
		where access_token = $1
`, accessToken)
	var result = ente.PublicFileUrlRow{}
	err := row.Scan(&result.LinkID, &result.FileID, &result.OwnerID, &result.IsDisabled, &result.EnableDownload, &result.ValidTill, &result.DeviceLimit, &result.PassHash, &result.Nonce, &result.MemLimit, &result.OpsLimit, &result.CreatedAt, &result.UpdatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, ente.ErrNotFound
		}
		return nil, stacktrace.Propagate(err, "failed to get public file url summary by token")
	}
	return &result, nil
}

// UpdateLink will update the row for corresponding public file token
func (pcr *FileLinkRepository) UpdateLink(ctx context.Context, pct ente.PublicFileUrlRow) error {
	_, err := pcr.DB.ExecContext(ctx, `UPDATE public_file_tokens SET valid_till = $1, device_limit = $2, 
                                    pw_hash = $3, pw_nonce = $4, mem_limit = $5, ops_limit = $6, enable_download = $7  
                                where id = $8`,
		pct.ValidTill, pct.DeviceLimit, pct.PassHash, pct.Nonce, pct.MemLimit, pct.OpsLimit, pct.EnableDownload, pct.LinkID)
	return stacktrace.Propagate(err, "failed to update public file token")
}

func (pcr *FileLinkRepository) GetUniqueAccessCount(ctx context.Context, linkId string) (int64, error) {
	row := pcr.DB.QueryRowContext(ctx, `SELECT count(*) FROM public_file_tokens_access_history WHERE id = $1`, linkId)
	var count int64 = 0
	err := row.Scan(&count)
	if err != nil {
		return -1, stacktrace.Propagate(err, "")
	}
	return count, nil
}

func (pcr *FileLinkRepository) RecordAccessHistory(ctx context.Context, shareID int64, ip string, ua string) error {
	_, err := pcr.DB.ExecContext(ctx, `INSERT INTO public_file_tokens_access_history 
    (id, ip, user_agent) VALUES ($1, $2, $3) 
    ON CONFLICT ON CONSTRAINT unique_access_id_ip_ua DO NOTHING;`,
		shareID, ip, ua)
	return stacktrace.Propagate(err, "failed to record access history")
}

// AccessedInPast returns true if the given ip, ua agent combination has accessed the url in the past
func (pcr *FileLinkRepository) AccessedInPast(ctx context.Context, shareID int64, ip string, ua string) (bool, error) {
	panic("not implemented, refactor &  public file")
}

// CleanupAccessHistory public_file_tokens_access_history where public_collection_tokens is disabled and the last updated time is older than 30 days
func (pcr *FileLinkRepository) CleanupAccessHistory(ctx context.Context) error {
	_, err := pcr.DB.ExecContext(ctx, `DELETE FROM public_file_tokens_access_history WHERE id IN (SELECT id FROM public_file_tokens WHERE is_disabled = TRUE AND updated_at < (now_utc_micro_seconds() - (24::BIGINT * 30 * 60 * 60 * 1000 * 1000)))`)
	if err != nil {
		return stacktrace.Propagate(err, "failed to clean up public file access history")
	}
	return nil
}
