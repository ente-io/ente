package public

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/ente-io/museum/ente/base"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
	"github.com/lib/pq"
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
) error {
	id, err := base.NewID("pft")
	if err != nil {
		return stacktrace.Propagate(err, "failed to generate new ID for public file token")
	}
	_, err = pcr.DB.ExecContext(ctx, `INSERT INTO public_file_tokens 
    (id, file_id, owner_id, access_token) VALUES ($1, $2, $3, $4)`,
		id, fileID, ownerID, token)
	if err != nil && err.Error() == "pq: duplicate key value violates unique constraint \"public_access_token_unique_idx\"" {
		return ente.ErrActiveLinkAlreadyExists
	}
	return stacktrace.Propagate(err, "failed to insert")
}

func (pcr *PublicFileRepository) DisableSharing(ctx context.Context, fileID int64) error {
	_, err := pcr.DB.ExecContext(ctx, `UPDATE public_file_tokens SET is_disabled = true where 
                                                             file_id = $1 and is_disabled = false`, fileID)
	return stacktrace.Propagate(err, "failed to disable sharing")
}

// GetCollectionToActivePublicURLMap will return map of collectionID to PublicURLs which are not disabled yet.
// Note: The url could be expired or deviceLimit is already reached
func (pcr *PublicFileRepository) GetCollectionToActivePublicURLMap(ctx context.Context, collectionIDs []int64) (map[int64][]ente.PublicURL, error) {
	rows, err := pcr.DB.QueryContext(ctx, `SELECT collection_id, access_token, valid_till, device_limit, enable_download, enable_collect, enable_join, pw_nonce, mem_limit, ops_limit FROM 
                                                   public_collection_tokens WHERE collection_id = ANY($1) and is_disabled = FALSE`,
		pq.Array(collectionIDs))
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer rows.Close()
	result := make(map[int64][]ente.PublicURL, 0)
	for _, cID := range collectionIDs {
		result[cID] = make([]ente.PublicURL, 0)
	}
	for rows.Next() {
		publicUrl := ente.PublicURL{}
		var collectionID int64
		var accessToken string
		var nonce *string
		var opsLimit, memLimit *int64
		if err = rows.Scan(&collectionID, &accessToken, &publicUrl.ValidTill, &publicUrl.DeviceLimit, &publicUrl.EnableDownload, &publicUrl.EnableCollect, &publicUrl.EnableJoin, &nonce, &memLimit, &opsLimit); err != nil {
			return nil, stacktrace.Propagate(err, "")
		}
		publicUrl.URL = pcr.GetAlbumUrl(accessToken)
		if nonce != nil {
			publicUrl.Nonce = nonce
			publicUrl.MemLimit = memLimit
			publicUrl.OpsLimit = opsLimit
			publicUrl.PasswordEnabled = true
		}
		result[collectionID] = append(result[collectionID], publicUrl)
	}
	return result, nil
}

// GetActivePublicCollectionToken will return ente.PublicCollectionToken for given collection ID
// Note: The token could be expired or deviceLimit is already reached
func (pcr *PublicFileRepository) GetActivePublicCollectionToken(ctx context.Context, collectionID int64) (ente.PublicCollectionToken, error) {
	row := pcr.DB.QueryRowContext(ctx, `SELECT id, collection_id, access_token, valid_till, device_limit, 
       is_disabled, pw_hash, pw_nonce, mem_limit, ops_limit, enable_download, enable_collect, enable_join FROM 
                                                   public_collection_tokens WHERE collection_id = $1 and is_disabled = FALSE`,
		collectionID)

	//defer rows.Close()
	ret := ente.PublicCollectionToken{}
	err := row.Scan(&ret.ID, &ret.CollectionID, &ret.Token, &ret.ValidTill, &ret.DeviceLimit,
		&ret.IsDisabled, &ret.PassHash, &ret.Nonce, &ret.MemLimit, &ret.OpsLimit, &ret.EnableDownload, &ret.EnableCollect, &ret.EnableJoin)
	if err != nil {
		return ente.PublicCollectionToken{}, stacktrace.Propagate(err, "")
	}
	return ret, nil
}

// UpdatePublicCollectionToken will update the row for corresponding public collection token
func (pcr *PublicFileRepository) UpdatePublicCollectionToken(ctx context.Context, pct ente.PublicCollectionToken) error {
	_, err := pcr.DB.ExecContext(ctx, `UPDATE public_collection_tokens SET valid_till = $1, device_limit = $2, 
                                    pw_hash = $3, pw_nonce = $4, mem_limit = $5, ops_limit = $6, enable_download = $7, enable_collect = $8, enable_join = $9 
                                where id = $10`,
		pct.ValidTill, pct.DeviceLimit, pct.PassHash, pct.Nonce, pct.MemLimit, pct.OpsLimit, pct.EnableDownload, pct.EnableCollect, pct.EnableJoin, pct.ID)
	return stacktrace.Propagate(err, "failed to update public collection token")
}

func (pcr *PublicFileRepository) GetUniqueAccessCount(ctx context.Context, shareId int64) (int64, error) {
	panic("not implemented, refactor &  public collection")
}

func (pcr *PublicFileRepository) RecordAccessHistory(ctx context.Context, shareID int64, ip string, ua string) error {
	panic("not implemented, refactor &  public collection")
}

// AccessedInPast returns true if the given ip, ua agent combination has accessed the url in the past
func (pcr *PublicFileRepository) AccessedInPast(ctx context.Context, shareID int64, ip string, ua string) (bool, error) {
	panic("not implemented, refactor &  public collection")
}

func (pcr *PublicFileRepository) GetFileUrlRowByToken(ctx context.Context, accessToken string) (*ente.PublicFileUrlRow, error) {
	row := pcr.DB.QueryRowContext(ctx,
		`SELECT id, file_id, is_disabled, valid_till, device_limit, password_info,
       created_at, updated_at
		from public_file_tokens 
		where access_token = $1
`, accessToken)
	var result = ente.PublicFileUrlRow{}
	err := row.Scan(&result.LinkID, &result.FileID, &result.IsDisabled, &result.ValidTill, &result.DeviceLimit, result.PasswordInfo, &result.CreatedAt, &result.UpdatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, ente.ErrNotFound
		}
		return nil, stacktrace.Propagate(err, "failed to get public file url summary by token")
	}
	return &result, nil
}

// CleanupAccessHistory public_collection_access_history where public_collection_tokens is disabled and the last updated time is older than 30 days
func (pcr *PublicFileRepository) CleanupAccessHistory(ctx context.Context) error {
	_, err := pcr.DB.ExecContext(ctx, `DELETE FROM public_collection_access_history WHERE share_id IN (SELECT id FROM public_collection_tokens WHERE is_disabled = TRUE AND updated_at < (now_utc_micro_seconds() - (24::BIGINT * 30 * 60 * 60 * 1000 * 1000)))`)
	if err != nil {
		return stacktrace.Propagate(err, "failed to clean up public collection access history")
	}
	return nil
}
