package public

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
	"github.com/lib/pq"
)

const BaseShareURL = "https://albums.ente.io/?t=%s"

// PublicCollectionRepository defines the methods for inserting, updating and
// retrieving entities related to public collections
type PublicCollectionRepository struct {
	DB        *sql.DB
	albumHost string
}

// NewPublicCollectionRepository ..
func NewPublicCollectionRepository(db *sql.DB, albumHost string) *PublicCollectionRepository {
	if albumHost == "" {
		albumHost = "https://albums.ente.io"
	}
	return &PublicCollectionRepository{
		DB:        db,
		albumHost: albumHost,
	}
}

func (pcr *PublicCollectionRepository) GetAlbumUrl(token string) string {
	return fmt.Sprintf("%s/?t=%s", pcr.albumHost, token)
}

func (pcr *PublicCollectionRepository) Insert(ctx context.Context,
	cID int64, token string, validTill int64, deviceLimit int, enableCollect bool, enableJoin *bool) error {
	// default value for enableJoin is true
	join := true
	if enableJoin != nil {
		join = *enableJoin
	}
	_, err := pcr.DB.ExecContext(ctx, `INSERT INTO public_collection_tokens 
    (collection_id, access_token, valid_till, device_limit, enable_collect, enable_join) VALUES ($1, $2, $3, $4, $5, $6)`,
		cID, token, validTill, deviceLimit, enableCollect, join)
	if err != nil && err.Error() == "pq: duplicate key value violates unique constraint \"public_active_collection_unique_idx\"" {
		return ente.ErrActiveLinkAlreadyExists
	}
	return stacktrace.Propagate(err, "failed to insert")
}

func (pcr *PublicCollectionRepository) DisableSharing(ctx context.Context, cID int64) error {
	_, err := pcr.DB.ExecContext(ctx, `UPDATE public_collection_tokens SET is_disabled = true where 
                                                             collection_id = $1 and is_disabled = false`, cID)
	return stacktrace.Propagate(err, "failed to disable sharing")
}

// GetCollectionToActivePublicURLMap will return map of collectionID to PublicURLs which are not disabled yet.
// Note: The url could be expired or deviceLimit is already reached
func (pcr *PublicCollectionRepository) GetCollectionToActivePublicURLMap(ctx context.Context, collectionIDs []int64) (map[int64][]ente.PublicURL, error) {
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
func (pcr *PublicCollectionRepository) GetActivePublicCollectionToken(ctx context.Context, collectionID int64) (ente.PublicCollectionToken, error) {
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
func (pcr *PublicCollectionRepository) UpdatePublicCollectionToken(ctx context.Context, pct ente.PublicCollectionToken) error {
	_, err := pcr.DB.ExecContext(ctx, `UPDATE public_collection_tokens SET valid_till = $1, device_limit = $2, 
                                    pw_hash = $3, pw_nonce = $4, mem_limit = $5, ops_limit = $6, enable_download = $7, enable_collect = $8, enable_join = $9 
                                where id = $10`,
		pct.ValidTill, pct.DeviceLimit, pct.PassHash, pct.Nonce, pct.MemLimit, pct.OpsLimit, pct.EnableDownload, pct.EnableCollect, pct.EnableJoin, pct.ID)
	return stacktrace.Propagate(err, "failed to update public collection token")
}

func (pcr *PublicCollectionRepository) RecordAbuseReport(ctx context.Context, accessCtx ente.PublicAccessContext,
	url string, reason string, details ente.AbuseReportDetails) error {
	_, err := pcr.DB.ExecContext(ctx, `INSERT INTO public_abuse_report 
    (share_id, ip, user_agent, url, reason, details) VALUES ($1, $2, $3, $4, $5, $6) 
    ON CONFLICT ON CONSTRAINT unique_report_sid_ip_ua DO UPDATE SET (reason, details) = ($5, $6)`,
		accessCtx.ID, accessCtx.IP, accessCtx.UserAgent, url, reason, details)
	return stacktrace.Propagate(err, "failed to record abuse report")
}

func (pcr *PublicCollectionRepository) GetAbuseReportCount(ctx context.Context, accessCtx ente.PublicAccessContext) (int64, error) {
	row := pcr.DB.QueryRowContext(ctx, `SELECT count(*) FROM public_abuse_report WHERE share_id = $1`, accessCtx.ID)
	var count int64 = 0
	err := row.Scan(&count)
	if err != nil {
		return -1, stacktrace.Propagate(err, "")
	}
	return count, nil
}

func (pcr *PublicCollectionRepository) GetUniqueAccessCount(ctx context.Context, shareId int64) (int64, error) {
	row := pcr.DB.QueryRowContext(ctx, `SELECT count(*) FROM public_collection_access_history WHERE share_id = $1`, shareId)
	var count int64 = 0
	err := row.Scan(&count)
	if err != nil {
		return -1, stacktrace.Propagate(err, "")
	}
	return count, nil
}

func (pcr *PublicCollectionRepository) RecordAccessHistory(ctx context.Context, shareID int64, ip string, ua string) error {
	_, err := pcr.DB.ExecContext(ctx, `INSERT INTO public_collection_access_history 
    (share_id, ip, user_agent) VALUES ($1, $2, $3) 
    ON CONFLICT ON CONSTRAINT unique_access_sid_ip_ua DO NOTHING;`,
		shareID, ip, ua)
	return stacktrace.Propagate(err, "failed to record access history")
}

// AccessedInPast returns true if the given ip, ua agent combination has accessed the url in the past
func (pcr *PublicCollectionRepository) AccessedInPast(ctx context.Context, shareID int64, ip string, ua string) (bool, error) {
	row := pcr.DB.QueryRowContext(ctx, `select share_id from public_collection_access_history where share_id =$1 and ip = $2 and user_agent = $3`,
		shareID, ip, ua)
	var tempID int64
	err := row.Scan(&tempID)
	if errors.Is(err, sql.ErrNoRows) {
		return false, nil
	}
	return true, stacktrace.Propagate(err, "failed to record access history")
}

func (pcr *PublicCollectionRepository) GetCollectionSummaryByToken(ctx context.Context, accessToken string) (ente.PublicCollectionSummary, error) {
	row := pcr.DB.QueryRowContext(ctx,
		`SELECT sct.id, sct.collection_id, sct.is_disabled, sct.valid_till, sct.device_limit, sct.pw_hash,
       sct.created_at, sct.updated_at, count(ah.share_id) 
		from public_collection_tokens sct
		LEFT JOIN public_collection_access_history ah ON sct.id = ah.share_id
		where access_token = $1
		group by sct.id`, accessToken)
	var result = ente.PublicCollectionSummary{}
	err := row.Scan(&result.ID, &result.CollectionID, &result.IsDisabled, &result.ValidTill, &result.DeviceLimit,
		&result.PassHash, &result.CreatedAt, &result.UpdatedAt, &result.DeviceAccessCount)
	if err != nil {
		return ente.PublicCollectionSummary{}, stacktrace.Propagate(err, "failed to get public collection summary")
	}
	return result, nil
}

func (pcr *PublicCollectionRepository) GetActivePublicTokenForUser(ctx context.Context, userID int64) ([]int64, error) {
	rows, err := pcr.DB.QueryContext(ctx, `select pt.collection_id from public_collection_tokens pt left join collections c on pt.collection_id = c.collection_id where pt.is_disabled = FALSE and c.owner_id= $1;`, userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer rows.Close()
	result := make([]int64, 0)
	for rows.Next() {
		var collectionID int64
		err = rows.Scan(&collectionID)
		if err != nil {
			return nil, stacktrace.Propagate(err, "")
		}
		result = append(result, collectionID)
	}
	return result, nil
}

// CleanupAccessHistory public_collection_access_history where public_collection_tokens is disabled and the last updated time is older than 30 days
func (pcr *PublicCollectionRepository) CleanupAccessHistory(ctx context.Context) error {
	_, err := pcr.DB.ExecContext(ctx, `DELETE FROM public_collection_access_history WHERE share_id IN (SELECT id FROM public_collection_tokens WHERE is_disabled = TRUE AND updated_at < (now_utc_micro_seconds() - (24::BIGINT * 30 * 60 * 60 * 1000 * 1000)))`)
	if err != nil {
		return stacktrace.Propagate(err, "failed to clean up public collection access history")
	}
	return nil
}
