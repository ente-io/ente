package public

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/ente-io/museum/ente/base"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
)

// PublicFileRepository defines the methods for inserting, updating and
// retrieving entities related to public file
type PublicFileRepository struct {
	DB        *sql.DB
	albumHost string
}

// NewPublicFileRepository ..
func NewPublicFileRepository(db *sql.DB, albumHost string) *PublicFileRepository {
	if albumHost == "" {
		albumHost = "https://albums.ente.io"
	}
	return &PublicFileRepository{
		DB:        db,
		albumHost: albumHost,
	}
}

func (pcr *PublicFileRepository) GetAlbumUrl(token string) string {
	return fmt.Sprintf("%s/?t=%s", pcr.albumHost, token)
}

func (pcr *PublicFileRepository) Insert(
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

func (pcr *PublicFileRepository) DisableSharing(ctx context.Context, fileID int64) error {
	_, err := pcr.DB.ExecContext(ctx, `UPDATE public_file_tokens SET is_disabled = true where 
                                                             file_id = $1 and is_disabled = false`, fileID)
	return stacktrace.Propagate(err, "failed to disable sharing")
}

func convertRowToFileUrl(rows *sql.Rows) ([]ente.FileUrl, error) {
	var fileUrls []ente.FileUrl
	for rows.Next() {
		fileUrl := ente.FileUrl{}
		var nonce *string
		var memLimit, opsLimit *int64
		err := rows.Scan(&fileUrl.LinkID, &fileUrl.OwnerID, &fileUrl.FileID, &fileUrl.ValidTill, &fileUrl.DeviceLimit, &nonce, &memLimit, &opsLimit, &fileUrl.EnableDownload, &fileUrl.CreatedAt)
		if err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan public file url row")
		}
		fileUrl.Nonce = nonce
		fileUrl.MemLimit = memLimit
		fileUrl.OpsLimit = opsLimit
		fileUrls = append(fileUrls, fileUrl)
	}
	return fileUrls, nil
}

// GetActiveFileUrlToken will return ente.PublicCollectionToken for given collection ID
// Note: The token could be expired or deviceLimit is already reached
func (pcr *PublicFileRepository) GetActiveFileUrlToken(ctx context.Context, collectionID int64) (*ente.PublicFileUrlRow, error) {
	row := pcr.DB.QueryRowContext(ctx, `SELECT id, file_id, owner_id, access_token, valid_till, device_limit, 
       is_disabled, pw_hash, pw_nonce, mem_limit, ops_limit, enable_download FROM 
                                                   public_file_tokens WHERE file_id = $1 and is_disabled = FALSE`,
		collectionID)

	//defer rows.Close()
	ret := ente.PublicFileUrlRow{}
	err := row.Scan(&ret.LinkID, &ret.FileID, ret.OwnerID, &ret.Token, &ret.ValidTill, &ret.DeviceLimit,
		&ret.IsDisabled, &ret.PassHash, &ret.Nonce, &ret.MemLimit, &ret.OpsLimit, &ret.EnableDownload)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &ret, nil
}

func (pcr *PublicFileRepository) GetFileUrlRowByToken(ctx context.Context, accessToken string) (*ente.PublicFileUrlRow, error) {
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
func (pcr *PublicFileRepository) UpdateLink(ctx context.Context, pct ente.PublicFileUrlRow) error {
	_, err := pcr.DB.ExecContext(ctx, `UPDATE public_file_tokens SET valid_till = $1, device_limit = $2, 
                                    pw_hash = $3, pw_nonce = $4, mem_limit = $5, ops_limit = $6, enable_download = $7  
                                where id = $8`,
		pct.ValidTill, pct.DeviceLimit, pct.PassHash, pct.Nonce, pct.MemLimit, pct.OpsLimit, pct.EnableDownload, pct.LinkID)
	return stacktrace.Propagate(err, "failed to update public file token")
}

func (pcr *PublicFileRepository) GetUniqueAccessCount(ctx context.Context, shareId int64) (int64, error) {
	panic("not implemented, refactor &  public file")
}

func (pcr *PublicFileRepository) RecordAccessHistory(ctx context.Context, shareID int64, ip string, ua string) error {
	panic("not implemented, refactor &  public file")
}

// AccessedInPast returns true if the given ip, ua agent combination has accessed the url in the past
func (pcr *PublicFileRepository) AccessedInPast(ctx context.Context, shareID int64, ip string, ua string) (bool, error) {
	panic("not implemented, refactor &  public file")
}

// CleanupAccessHistory public_file_tokens_access_history where public_collection_tokens is disabled and the last updated time is older than 30 days
func (pcr *PublicFileRepository) CleanupAccessHistory(ctx context.Context) error {
	_, err := pcr.DB.ExecContext(ctx, `DELETE FROM public_file_tokens_access_history WHERE id IN (SELECT id FROM public_file_tokens WHERE is_disabled = TRUE AND updated_at < (now_utc_micro_seconds() - (24::BIGINT * 30 * 60 * 60 * 1000 * 1000)))`)
	if err != nil {
		return stacktrace.Propagate(err, "failed to clean up public file access history")
	}
	return nil
}
