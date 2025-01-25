package repo

import (
	"context"
	"database/sql"
	"fmt"
	"strconv"
	"strings"
	t "time"

	"github.com/prometheus/client_golang/prometheus"

	"github.com/sirupsen/logrus"

	"github.com/ente-io/stacktrace"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/crypto"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/lib/pq"
)

// CollectionRepository defines the methods for inserting, updating and
// retrieving collection entities from the underlying repository
type CollectionRepository struct {
	DB                   *sql.DB
	FileRepo             *FileRepository
	PublicCollectionRepo *PublicCollectionRepository
	TrashRepo            *TrashRepository
	SecretEncryptionKey  []byte
	QueueRepo            *QueueRepository
	LatencyLogger        *prometheus.HistogramVec
}

type SharedCollection struct {
	CollectionID int64
	ToUserID     int64
	FromUserID   int64
}

// Create creates a collection
func (repo *CollectionRepository) Create(c ente.Collection) (ente.Collection, error) {

	// Check if the app type can create collection
	if !ente.App(c.App).IsValidForCollection() {
		return ente.Collection{}, ente.ErrInvalidApp
	}

	err := repo.DB.QueryRow(`INSERT INTO collections(owner_id, encrypted_key, key_decryption_nonce, name, encrypted_name, name_decryption_nonce, type, attributes, updation_time, magic_metadata, pub_magic_metadata, app) 
		VALUES($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING collection_id`,
		c.Owner.ID, c.EncryptedKey, c.KeyDecryptionNonce, c.Name, c.EncryptedName, c.NameDecryptionNonce, c.Type, c.Attributes, c.UpdationTime, c.MagicMetadata, c.PublicMagicMetadata, c.App).Scan(&c.ID)
	if err != nil {
		if err.Error() == "pq: duplicate key value violates unique constraint \"collections_favorites_constraint_index\"" {
			return ente.Collection{}, ente.ErrFavoriteCollectionAlreadyExist
		} else if err.Error() == "pq: duplicate key value violates unique constraint \"collections_uncategorized_constraint_index_v2\"" {
			return ente.Collection{}, ente.ErrUncategorizeCollectionAlreadyExists
		}
	}
	return c, stacktrace.Propagate(err, "")
}

// Get returns a collection identified by the collectionID
func (repo *CollectionRepository) Get(collectionID int64) (ente.Collection, error) {
	row := repo.DB.QueryRow(`SELECT collection_id, owner_id, encrypted_key, key_decryption_nonce, name, encrypted_name, name_decryption_nonce, type, attributes, updation_time, is_deleted, magic_metadata, pub_magic_metadata
		FROM collections
		WHERE collection_id = $1`, collectionID)
	var c ente.Collection
	var name, encryptedName, nameDecryptionNonce sql.NullString
	if err := row.Scan(&c.ID, &c.Owner.ID, &c.EncryptedKey, &c.KeyDecryptionNonce, &name, &encryptedName, &nameDecryptionNonce, &c.Type, &c.Attributes, &c.UpdationTime, &c.IsDeleted, &c.MagicMetadata, &c.PublicMagicMetadata); err != nil {
		return c, stacktrace.Propagate(err, "")
	}
	if name.Valid && len(name.String) > 0 {
		c.Name = name.String
	} else {
		c.EncryptedName = encryptedName.String
		c.NameDecryptionNonce = nameDecryptionNonce.String
	}
	urlMap, err := repo.PublicCollectionRepo.GetCollectionToActivePublicURLMap(context.Background(), []int64{collectionID})
	if err != nil {
		return ente.Collection{}, stacktrace.Propagate(err, "failed to get publicURL info")
	}
	if publicUrls, ok := urlMap[collectionID]; ok {
		c.PublicURLs = publicUrls
	}
	return c, nil
}
func (repo *CollectionRepository) GetCollectionByType(userID int64, collectionType string) (ente.Collection, error) {
	row := repo.DB.QueryRow(`SELECT collection_id, owner_id, encrypted_key, key_decryption_nonce, name, encrypted_name, name_decryption_nonce, type, attributes, updation_time, is_deleted, magic_metadata
		FROM collections
		WHERE owner_id = $1 and type = $2`, userID, collectionType)
	var c ente.Collection
	var name, encryptedName, nameDecryptionNonce sql.NullString
	if err := row.Scan(&c.ID, &c.Owner.ID, &c.EncryptedKey, &c.KeyDecryptionNonce, &name, &encryptedName, &nameDecryptionNonce, &c.Type, &c.Attributes, &c.UpdationTime, &c.IsDeleted, &c.MagicMetadata); err != nil {
		return c, stacktrace.Propagate(err, "")
	}
	if name.Valid && len(name.String) > 0 {
		c.Name = name.String
	} else {
		c.EncryptedName = encryptedName.String
		c.NameDecryptionNonce = nameDecryptionNonce.String
	}
	return c, nil
}

// GetCollectionsOwnedByUser returns the list of collections that a user owns
// todo: refactor this method
func (repo *CollectionRepository) GetCollectionsOwnedByUser(userID int64, updationTime int64, app ente.App) ([]ente.Collection, error) {
	rows, err := repo.DB.Query(`
		SELECT collections.collection_id, collections.owner_id, collections.encrypted_key, collections.key_decryption_nonce, collections.name, collections.encrypted_name, collections.name_decryption_nonce, collections.type, collections.app, collections.attributes, collections.updation_time, collections.is_deleted, collections.magic_metadata, collections.pub_magic_metadata
		FROM collections
		WHERE collections.owner_id = $1 AND collections.updation_time > $2 AND app = $3`, userID, updationTime, strings.ToLower(string(app)))
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer rows.Close()
	collectionIDs := make([]int64, 0)
	collections := make([]ente.Collection, 0)
	result := make([]ente.Collection, 0)
	for rows.Next() {
		var c ente.Collection
		var name, encryptedName, nameDecryptionNonce sql.NullString
		if err := rows.Scan(&c.ID, &c.Owner.ID, &c.EncryptedKey, &c.KeyDecryptionNonce, &name, &encryptedName, &nameDecryptionNonce, &c.Type, &c.App, &c.Attributes, &c.UpdationTime, &c.IsDeleted, &c.MagicMetadata, &c.PublicMagicMetadata); err != nil {
			return collections, stacktrace.Propagate(err, "")
		}
		if name.Valid && len(name.String) > 0 {
			c.Name = name.String
		} else {
			c.EncryptedName = encryptedName.String
			c.NameDecryptionNonce = nameDecryptionNonce.String
		}
		// TODO: Pull this information in the previous query
		sharees, err := repo.GetSharees(c.ID)
		if err != nil {
			return collections, stacktrace.Propagate(err, "")
		}
		c.Sharees = sharees
		collections = append(collections, c)
		collectionIDs = append(collectionIDs, c.ID)
	}

	urlMap, err := repo.PublicCollectionRepo.GetCollectionToActivePublicURLMap(context.Background(), collectionIDs)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to get publicURL info")
	}
	for _, c := range collections {
		c.PublicURLs = urlMap[c.ID]
		result = append(result, c)
	}

	return result, nil
}

func (repo *CollectionRepository) GetCollectionsOwnedByUserV2(userID int64, updationTime int64, app ente.App) ([]ente.Collection, error) {
	rows, err := repo.DB.Query(`
		SELECT 
c.collection_id, c.owner_id, c.encrypted_key,c.key_decryption_nonce, c.name, c.encrypted_name, c.name_decryption_nonce, c.type, c.app, c.attributes, c.updation_time, c.is_deleted, c.magic_metadata, c.pub_magic_metadata,
users.user_id, users.encrypted_email, users.email_decryption_nonce, cs.role_type,
pct.access_token, pct.valid_till, pct.device_limit, pct.created_at, pct.updated_at, pct.pw_hash, pct.pw_nonce, pct.mem_limit, pct.ops_limit, pct.enable_download, pct.enable_collect, pct.enable_join 
    FROM collections c
    LEFT JOIN collection_shares cs
    ON (cs.collection_id = c.collection_id AND cs.is_deleted = false)
    LEFT JOIN users 
    ON (cs.to_user_id = users.user_id AND users.encrypted_email IS NOT NULL)
    LEFT JOIN public_collection_tokens pct
    ON (pct.collection_id = c.collection_id and pct.is_disabled=FALSE)
    WHERE c.owner_id = $1 AND c.updation_time > $2 and c.app = $3`, userID, updationTime, string(app))
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer rows.Close()
	collectionIDToValMap := map[int64]*ente.Collection{}
	addPublicUrlMap := map[string]bool{}
	result := make([]ente.Collection, 0)
	for rows.Next() {
		var c ente.Collection
		var name, encryptedName, nameDecryptionNonce sql.NullString
		var pctDeviceLimit sql.NullInt32
		var pctEnableDownload, pctEnableCollect, pctEnableJoin sql.NullBool
		var shareUserID, pctValidTill, pctCreatedAt, pctUpdatedAt, pctMemLimit, pctOpsLimit sql.NullInt64
		var encryptedEmail, nonce []byte
		var shareeRoleType, pctToken, pctPwHash, pctPwNonce sql.NullString

		if err := rows.Scan(&c.ID, &c.Owner.ID, &c.EncryptedKey, &c.KeyDecryptionNonce, &name, &encryptedName, &nameDecryptionNonce, &c.Type, &c.App, &c.Attributes, &c.UpdationTime, &c.IsDeleted, &c.MagicMetadata, &c.PublicMagicMetadata,
			&shareUserID, &encryptedEmail, &nonce, &shareeRoleType,
			&pctToken, &pctValidTill, &pctDeviceLimit, &pctCreatedAt, &pctUpdatedAt, &pctPwHash, &pctPwNonce, &pctMemLimit, &pctOpsLimit, &pctEnableDownload, &pctEnableCollect, &pctEnableJoin); err != nil {
			return nil, stacktrace.Propagate(err, "")
		}

		if _, ok := collectionIDToValMap[c.ID]; !ok {
			if name.Valid && len(name.String) > 0 {
				c.Name = name.String
			} else {
				c.EncryptedName = encryptedName.String
				c.NameDecryptionNonce = nameDecryptionNonce.String
			}
			c.Sharees = make([]ente.CollectionUser, 0)
			c.PublicURLs = make([]ente.PublicURL, 0)
			collectionIDToValMap[c.ID] = &c

		}
		currentCollection := collectionIDToValMap[c.ID]
		if shareUserID.Valid {
			sharedUser := ente.CollectionUser{
				ID:   shareUserID.Int64,
				Role: ente.ConvertStringToCollectionParticipantRole(shareeRoleType.String),
			}
			email, err := crypto.Decrypt(encryptedEmail, repo.SecretEncryptionKey, nonce)
			if err != nil {
				return nil, stacktrace.Propagate(err, "")
			}
			sharedUser.Email = email
			currentCollection.Sharees = append(currentCollection.Sharees, sharedUser)
		}

		if pctToken.Valid {
			if _, ok := addPublicUrlMap[pctToken.String]; !ok {
				addPublicUrlMap[pctToken.String] = true
				url := ente.PublicURL{
					URL:             repo.PublicCollectionRepo.GetAlbumUrl(pctToken.String),
					DeviceLimit:     int(pctDeviceLimit.Int32),
					ValidTill:       pctValidTill.Int64,
					EnableDownload:  pctEnableDownload.Bool,
					EnableCollect:   pctEnableCollect.Bool,
					PasswordEnabled: pctPwNonce.Valid,
					EnableJoin:      pctEnableJoin.Bool,
				}
				if pctPwNonce.Valid {
					url.Nonce = &pctPwNonce.String
					url.MemLimit = &pctMemLimit.Int64
					url.OpsLimit = &pctOpsLimit.Int64
				}
				currentCollection.PublicURLs = append(currentCollection.PublicURLs, url)
			}
		}
	}
	for _, collection := range collectionIDToValMap {
		result = append(result, *collection)
	}
	return result, nil
}

// GetCollectionsSharedWithUser returns the list of collections that are shared
// with a user
func (repo *CollectionRepository) GetCollectionsSharedWithUser(userID int64, updationTime int64, app ente.App) ([]ente.Collection, error) {
	rows, err := repo.DB.Query(`
		SELECT collections.collection_id, collections.owner_id, users.encrypted_email, users.email_decryption_nonce, collection_shares.encrypted_key, collections.name, collections.encrypted_name, collections.name_decryption_nonce, collections.type, collections.app, collections.pub_magic_metadata, collection_shares.magic_metadata, collections.updation_time, collection_shares.is_deleted
		FROM collections
		INNER JOIN users
			ON collections.owner_id = users.user_id
		INNER JOIN collection_shares
			ON collections.collection_id = collection_shares.collection_id AND collection_shares.to_user_id = $1 AND (collection_shares.updation_time > $2 OR collections.updation_time > $2) AND users.encrypted_email IS NOT NULL AND app = $3`, userID, updationTime, string(app))
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer rows.Close()

	collections := make([]ente.Collection, 0)
	for rows.Next() {
		var c ente.Collection
		var collectionName, encryptedName, nameDecryptionNonce sql.NullString
		var encryptedEmail, emailDecryptionNonce []byte
		if err := rows.Scan(&c.ID, &c.Owner.ID, &encryptedEmail, &emailDecryptionNonce, &c.EncryptedKey, &collectionName, &encryptedName, &nameDecryptionNonce, &c.Type, &c.App, &c.PublicMagicMetadata, &c.SharedMagicMetadata, &c.UpdationTime, &c.IsDeleted); err != nil {
			return collections, stacktrace.Propagate(err, "")
		}
		if collectionName.Valid && len(collectionName.String) > 0 {
			c.Name = collectionName.String
		} else {
			c.EncryptedName = encryptedName.String
			c.NameDecryptionNonce = nameDecryptionNonce.String
		}
		// if collection is unshared, no need to parse owner's email. Email decryption will fail if the owner's account is deleted
		if c.IsDeleted {
			c.Owner.Email = ""
		} else {
			email, err := crypto.Decrypt(encryptedEmail, repo.SecretEncryptionKey, emailDecryptionNonce)
			if err != nil {
				return collections, stacktrace.Propagate(err, "failed to decrypt email")
			}
			c.Owner.Email = email
		}
		// TODO: Pull this information in the previous query
		if c.IsDeleted {
			// if collection is deleted or unshared, c.IsDeleted will be true. In both cases, we should not send
			// back information about other sharees
			c.Sharees = make([]ente.CollectionUser, 0)
		} else {
			sharees, err := repo.GetSharees(c.ID)
			if err != nil {
				return collections, stacktrace.Propagate(err, "")
			}
			c.Sharees = sharees
		}
		collections = append(collections, c)
	}
	return collections, nil
}

// GetCollectionIDsSharedWithUser returns the list of collections that a user has access to
func (repo *CollectionRepository) GetCollectionIDsSharedWithUser(userID int64) ([]int64, error) {
	rows, err := repo.DB.Query(`
		SELECT collection_id
		FROM collection_shares
		WHERE collection_shares.to_user_id = $1
		AND collection_shares.is_deleted = $2`, userID, false)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer rows.Close()

	cIDs := make([]int64, 0)
	for rows.Next() {
		var cID int64
		if err := rows.Scan(&cID); err != nil {
			return cIDs, stacktrace.Propagate(err, "")
		}
		cIDs = append(cIDs, cID)
	}
	return cIDs, nil
}

func (repo *CollectionRepository) GetCollectionsSharedWithOrByUser(userID int64) ([]int64, error) {
	rows, err := repo.DB.Query(`
		SELECT collection_id
		FROM collection_shares
		WHERE (to_user_id = $1 OR from_user_id = $1)
		AND is_deleted = $2`, userID, false)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer rows.Close()

	cIDs := make([]int64, 0)
	for rows.Next() {
		var cID int64
		if err := rows.Scan(&cID); err != nil {
			return cIDs, stacktrace.Propagate(err, "")
		}
		cIDs = append(cIDs, cID)
	}
	return cIDs, nil

}

// GetCollectionIDsOwnedByUser returns the map of collectionID (owned by user) to collection deletion status
func (repo *CollectionRepository) GetCollectionIDsOwnedByUser(userID int64) (map[int64]bool, error) {
	rows, err := repo.DB.Query(`
		SELECT collection_id, is_deleted
		FROM collections
		WHERE owner_id = $1
		AND is_deleted = $2`, userID, false)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer rows.Close()

	result := make(map[int64]bool, 0)

	for rows.Next() {
		var cID int64
		var isDeleted bool
		if err := rows.Scan(&cID, &isDeleted); err != nil {
			return result, stacktrace.Propagate(err, "")
		}
		result[cID] = isDeleted
	}
	return result, nil
}

// GetAllSharedCollections returns list of SharedCollection in which the given user is involed
func (repo *CollectionRepository) GetAllSharedCollections(ctx context.Context, userID int64) ([]SharedCollection, error) {
	rows, err := repo.DB.QueryContext(ctx, `SELECT collection_id, to_user_id, from_user_id
		FROM collection_shares
		WHERE (to_user_id = $1 or from_user_id = $1)
		AND is_deleted = $2`, userID, false)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer rows.Close()
	result := make([]SharedCollection, 0)
	for rows.Next() {
		logrus.Info("reading row")
		var sharedCollection SharedCollection
		if err := rows.Scan(&sharedCollection.CollectionID, &sharedCollection.ToUserID, &sharedCollection.FromUserID); err != nil {
			logrus.WithError(err).Info("failed to scan")
			return result, stacktrace.Propagate(err, "")
		}
		result = append(result, sharedCollection)
	}
	return result, nil
}

// DoesFileExistInCollections returns true if the file exists in one of the
// provided collections
func (repo *CollectionRepository) DoesFileExistInCollections(fileID int64, cIDs []int64) (bool, error) {
	var exists bool
	err := repo.DB.QueryRow(`SELECT EXISTS (SELECT 1 FROM collection_files WHERE file_id = $1 AND is_deleted = $2 AND collection_id = ANY ($3))`,
		fileID, false, pq.Array(cIDs)).Scan(&exists)
	return exists, stacktrace.Propagate(err, "")
}

func (repo *CollectionRepository) DoAllFilesExistInGivenCollections(fileIDs []int64, cIDs []int64) error {
	// Query to get all distinct file_ids that exist in the collections
	rows, err := repo.DB.Query(`
        SELECT DISTINCT file_id 
        FROM collection_files 
        WHERE file_id = ANY ($1) 
        AND is_deleted = false 
        AND collection_id = ANY ($2)`,
		pq.Array(fileIDs), pq.Array(cIDs))

	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	defer rows.Close()

	// Create a map of input fileIDs for easy lookup
	fileIDMap := make(map[int64]bool)
	for _, id := range fileIDs {
		fileIDMap[id] = false // false means not found yet
	}
	// Mark files that were found
	for rows.Next() {
		var fileID int64
		if err := rows.Scan(&fileID); err != nil {
			return stacktrace.Propagate(err, "")
		}
		fileIDMap[fileID] = true // mark as found
	}

	if err = rows.Err(); err != nil {
		return stacktrace.Propagate(err, "")
	}

	// Collect missing files
	var missingFiles []int64
	for id, found := range fileIDMap {
		if !found {
			missingFiles = append(missingFiles, id)
		}
	}
	if len(missingFiles) > 0 {
		return stacktrace.Propagate(fmt.Errorf("missing files %v", missingFiles), "")
	}
	return nil
}

// VerifyAllFileIDsExistsInCollection returns error if the fileIDs don't exist in the collection
func (repo *CollectionRepository) VerifyAllFileIDsExistsInCollection(ctx context.Context, cID int64, fileIDs []int64) error {
	fileIdMap := make(map[int64]bool)
	rows, err := repo.DB.QueryContext(ctx, `SELECT file_id FROM collection_files WHERE collection_id = $1 AND is_deleted = $2 AND file_id = ANY ($3)`,
		cID, false, pq.Array(fileIDs))
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	for rows.Next() {
		var fileID int64
		if err := rows.Scan(&fileID); err != nil {
			return stacktrace.Propagate(err, "")
		}
		fileIdMap[fileID] = true
	}
	// find fileIds that are not present in the collection
	for _, fileID := range fileIDs {
		if _, ok := fileIdMap[fileID]; !ok {
			return stacktrace.Propagate(fmt.Errorf("fileID %d not found in collection %d", fileID, cID), "")
		}
	}
	return nil
}

// GetCollectionShareeRole returns true if the collection is shared with the user
func (repo *CollectionRepository) GetCollectionShareeRole(cID int64, userID int64) (*ente.CollectionParticipantRole, error) {
	var role *ente.CollectionParticipantRole
	err := repo.DB.QueryRow(`(SELECT role_type FROM collection_shares WHERE collection_id = $1 AND to_user_id = $2 AND is_deleted = $3)`,
		cID, userID, false).Scan(&role)
	return role, stacktrace.Propagate(err, "")
}

func (repo *CollectionRepository) GetOwnerID(collectionID int64) (int64, error) {
	row := repo.DB.QueryRow(`SELECT owner_id FROM collections WHERE collection_id = $1`, collectionID)
	var ownerID int64
	err := row.Scan(&ownerID)
	return ownerID, stacktrace.Propagate(err, "failed to get collection owner")
}

// GetCollectionsFilesCount returns the number of non-deleted files which are present in the given collection
func (repo *CollectionRepository) GetCollectionsFilesCount(collectionID int64) (int64, error) {
	row := repo.DB.QueryRow(`SELECT count(*) FROM collection_files WHERE collection_id=$1 AND is_deleted = false`, collectionID)
	var count int64 = 0
	err := row.Scan(&count)
	if err != nil {
		return -1, stacktrace.Propagate(err, "")
	}
	return count, nil
}

// Share shares a collection with a userID
func (repo *CollectionRepository) Share(
	collectionID int64,
	fromUserID int64,
	toUserID int64,
	encryptedKey string,
	role ente.CollectionParticipantRole,
	updationTime int64) error {
	context := context.Background()
	tx, err := repo.DB.BeginTx(context, nil)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if role != ente.VIEWER && role != ente.COLLABORATOR {
		err = fmt.Errorf("invalid role %s", string(role))
		return stacktrace.Propagate(err, "")
	}
	_, err = tx.ExecContext(context, `INSERT INTO collection_shares(collection_id, from_user_id, to_user_id, encrypted_key, updation_time, role_type) VALUES($1, $2, $3, $4, $5, $6)
		ON CONFLICT (collection_id, from_user_id, to_user_id)
		DO UPDATE SET(is_deleted, updation_time, role_type) = (FALSE, $5, $6)`,
		collectionID, fromUserID, toUserID, encryptedKey, updationTime, role)
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	_, err = tx.ExecContext(context, `UPDATE collections SET updation_time = $1 WHERE collection_id = $2`, updationTime, collectionID)
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	err = tx.Commit()
	return stacktrace.Propagate(err, "")
}

// UpdateShareeMetadata shares a collection with a userID
func (repo *CollectionRepository) UpdateShareeMetadata(
	collectionID int64,
	ownerUserID int64,
	shareeUserID int64,
	metadata ente.MagicMetadata,
	updationTime int64) error {
	context := context.Background()
	tx, err := repo.DB.BeginTx(context, nil)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	// Update collection_shares metadata if the collection is not deleted
	sqlResult, err := tx.ExecContext(context, `UPDATE collection_shares SET magic_metadata = $1, updation_time = $2  WHERE collection_id = $3 AND from_user_id = $4 AND to_user_id = $5 AND is_deleted = $6`,
		metadata, updationTime, collectionID, ownerUserID, shareeUserID, false)
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	// verify that only one row is affected
	affected, err := sqlResult.RowsAffected()
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	if affected != 1 {
		tx.Rollback()
		err = fmt.Errorf("invalid number of rows affected %d", affected)
		return stacktrace.Propagate(err, "")
	}

	_, err = tx.ExecContext(context, `UPDATE collections SET updation_time = $1 WHERE collection_id = $2`, updationTime, collectionID)
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	err = tx.Commit()
	return stacktrace.Propagate(err, "")
}

// UnShare un-shares a collection from a userID
func (repo *CollectionRepository) UnShare(collectionID int64, toUserID int64) error {
	updationTime := time.Microseconds()
	context := context.Background()
	tx, err := repo.DB.BeginTx(context, nil)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	_, err = tx.ExecContext(context, `UPDATE collection_shares 
		SET is_deleted = $1, updation_time = $2 
		WHERE collection_id = $3 AND to_user_id = $4`, true, updationTime, collectionID, toUserID)
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	// remove all the files which were added by this user
	// todo: should we also add c_owner_id != toUserId
	_, err = tx.ExecContext(context, `UPDATE collection_files 
		SET is_deleted = $1, updation_time = $2 
		WHERE collection_id = $3 AND f_owner_id = $4`, true, updationTime, collectionID, toUserID)
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}

	_, err = tx.ExecContext(context, `UPDATE collections SET updation_time = $1 
		WHERE collection_id = $2`, updationTime, collectionID)
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	err = tx.Commit()
	return stacktrace.Propagate(err, "")
}

// AddFiles adds files to a collection
func (repo *CollectionRepository) AddFiles(
	collectionID int64,
	collectionOwnerID int64,
	files []ente.CollectionFileItem,
	fileOwnerID int64,
) error {
	updationTime := time.Microseconds()
	context := context.Background()
	tx, err := repo.DB.BeginTx(context, nil)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	for _, file := range files {
		_, err := tx.ExecContext(context, `INSERT INTO collection_files
			(collection_id, file_id, encrypted_key, key_decryption_nonce, is_deleted, updation_time, c_owner_id, f_owner_id)
			VALUES($1, $2, $3, $4, $5, $6, $7, $8)
			ON CONFLICT ON CONSTRAINT unique_collection_files_cid_fid
			DO UPDATE SET(is_deleted, updation_time) = ($5, $6)`, collectionID, file.ID, file.EncryptedKey,
			file.KeyDecryptionNonce, false, updationTime, collectionOwnerID, fileOwnerID)
		if err != nil {
			tx.Rollback()
			return stacktrace.Propagate(err, "")
		}
	}
	_, err = tx.ExecContext(context, `UPDATE collections SET updation_time = $1
		 WHERE collection_id = $2`, updationTime, collectionID)
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	err = tx.Commit()
	return stacktrace.Propagate(err, "")
}

func (repo *CollectionRepository) RestoreFiles(ctx context.Context, userID int64, collectionID int64, newCollectionFiles []ente.CollectionFileItem) error {
	fileIDs := make([]int64, 0)
	for _, newFile := range newCollectionFiles {
		fileIDs = append(fileIDs, newFile.ID)
	}
	// verify that all files are restorable
	_, canRestoreAllFiles, err := repo.TrashRepo.GetFilesInTrashState(ctx, userID, fileIDs)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if !canRestoreAllFiles {
		return stacktrace.Propagate(ente.ErrBadRequest, "some fileIDs are not restorable")
	}

	tx, err := repo.DB.BeginTx(ctx, nil)
	updationTime := time.Microseconds()
	if err != nil {
		return stacktrace.Propagate(err, "")
	}

	for _, file := range newCollectionFiles {
		_, err := tx.ExecContext(ctx, `INSERT INTO collection_files
			(collection_id, file_id, encrypted_key, key_decryption_nonce, is_deleted, updation_time, c_owner_id, f_owner_id)
			VALUES($1, $2, $3, $4, $5, $6, $7, $8)
			ON CONFLICT ON CONSTRAINT unique_collection_files_cid_fid
			DO UPDATE SET(is_deleted, updation_time) = ($5, $6)`, collectionID, file.ID, file.EncryptedKey,
			file.KeyDecryptionNonce, false, updationTime, userID, userID)
		if err != nil {
			tx.Rollback()
			return stacktrace.Propagate(err, "")
		}
	}
	_, err = tx.ExecContext(ctx, `UPDATE collections SET updation_time = $1
		 WHERE collection_id = $2`, updationTime, collectionID)
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}

	_, err = tx.ExecContext(ctx, `UPDATE trash SET is_restored = true
		 WHERE user_id = $1 and file_id = ANY ($2)`, userID, pq.Array(fileIDs))
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	return tx.Commit()
}

// RemoveFilesV3 just remove the entries from the collection. This method assume that collection owner is
// different from the file owners
func (repo *CollectionRepository) RemoveFilesV3(context context.Context, collectionID int64, fileIDs []int64) error {
	updationTime := time.Microseconds()
	tx, err := repo.DB.BeginTx(context, nil)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	_, err = tx.ExecContext(context, `UPDATE collection_files 
		SET is_deleted = $1, updation_time = $2 WHERE collection_id = $3 AND file_id = ANY($4)`,
		true, updationTime, collectionID, pq.Array(fileIDs))
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	_, err = tx.ExecContext(context, `UPDATE collections SET updation_time = $1
		WHERE collection_id = $2`, updationTime, collectionID)
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	err = tx.Commit()
	return stacktrace.Propagate(err, "")
}

// MoveFiles move files from one collection to another collection
func (repo *CollectionRepository) MoveFiles(ctx context.Context,
	toCollectionID int64, fromCollectionID int64,
	fileItems []ente.CollectionFileItem,
	collectionOwner int64,
	fileOwner int64,
) error {
	if collectionOwner != fileOwner {
		return fmt.Errorf("move is not supported when collection and file onwer are different")
	}
	updationTime := time.Microseconds()
	tx, err := repo.DB.BeginTx(ctx, nil)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	fileIDs := make([]int64, 0)
	for _, file := range fileItems {
		fileIDs = append(fileIDs, file.ID)
		_, err := tx.ExecContext(ctx, `INSERT INTO collection_files
			(collection_id, file_id, encrypted_key, key_decryption_nonce, is_deleted, updation_time, c_owner_id, f_owner_id)
			VALUES($1, $2, $3, $4, $5, $6, $7, $8)
			ON CONFLICT ON CONSTRAINT unique_collection_files_cid_fid
			DO UPDATE SET(is_deleted, updation_time) = ($5, $6)`, toCollectionID, file.ID, file.EncryptedKey,
			file.KeyDecryptionNonce, false, updationTime, collectionOwner, fileOwner)
		if err != nil {
			if rollbackErr := tx.Rollback(); rollbackErr != nil {
				logrus.WithError(rollbackErr).Error("transaction rollback failed")
				return stacktrace.Propagate(rollbackErr, "")
			}
			return stacktrace.Propagate(err, "")
		}
	}
	_, err = tx.ExecContext(ctx, `UPDATE collection_files 
		SET is_deleted = $1, updation_time = $2 WHERE collection_id = $3 AND file_id = ANY($4)`,
		true, updationTime, fromCollectionID, pq.Array(fileIDs))
	if err != nil {
		if rollbackErr := tx.Rollback(); rollbackErr != nil {
			logrus.WithError(rollbackErr).Error("transaction rollback failed")
			return stacktrace.Propagate(rollbackErr, "")
		}
		return stacktrace.Propagate(err, "")
	}
	_, err = tx.ExecContext(ctx, `UPDATE collections SET updation_time = $1
		 WHERE (collection_id = $2 or collection_id = $3 )`, updationTime, toCollectionID, fromCollectionID)
	if err != nil {
		if rollbackErr := tx.Rollback(); rollbackErr != nil {
			logrus.WithError(rollbackErr).Error("transaction rollback failed")
			return stacktrace.Propagate(rollbackErr, "")
		}
		return stacktrace.Propagate(err, "")
	}
	return tx.Commit()
}

// GetDiff returns the diff of files added or modified within a collection since
// the specified time
func (repo *CollectionRepository) GetDiff(collectionID int64, sinceTime int64, limit int) ([]ente.File, error) {
	startTime := t.Now()
	defer func() {
		repo.LatencyLogger.WithLabelValues("CollectionRepo.GetDiff").
			Observe(float64(t.Since(startTime).Milliseconds()))
	}()
	rows, err := repo.DB.Query(`
		SELECT files.file_id, files.owner_id, collection_files.collection_id, collection_files.c_owner_id,
			collection_files.encrypted_key, collection_files.key_decryption_nonce,
			files.file_decryption_header, files.thumbnail_decryption_header,
			files.metadata_decryption_header, files.encrypted_metadata, files.magic_metadata, files.pub_magic_metadata, 
			files.info, collection_files.is_deleted, collection_files.updation_time
		FROM files
		INNER JOIN collection_files
		ON collection_files.file_id = files.file_id
			AND collection_files.collection_id = $1
			AND collection_files.updation_time > $2
		ORDER BY collection_files.updation_time LIMIT $3`,
		collectionID, sinceTime, limit)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return convertRowsToFiles(rows)
}

func (repo *CollectionRepository) GetFilesWithVersion(collectionID int64, updateAtTime int64) ([]ente.File, error) {
	startTime := t.Now()
	defer func() {
		repo.LatencyLogger.WithLabelValues("CollectionRepo.GetFilesWithVersion").
			Observe(float64(t.Since(startTime).Milliseconds()))
	}()
	rows, err := repo.DB.Query(`
		SELECT files.file_id, files.owner_id, collection_files.collection_id, collection_files.c_owner_id,
			collection_files.encrypted_key, collection_files.key_decryption_nonce,
			files.file_decryption_header, files.thumbnail_decryption_header,
			files.metadata_decryption_header, files.encrypted_metadata, files.magic_metadata, files.pub_magic_metadata,
			files.info, collection_files.is_deleted, collection_files.updation_time
		FROM files
		INNER JOIN collection_files
		ON collection_files.file_id = files.file_id
			AND collection_files.collection_id = $1
			AND collection_files.updation_time = $2`,
		collectionID, updateAtTime)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return convertRowsToFiles(rows)
}

func (repo *CollectionRepository) GetFile(collectionID int64, fileID int64) ([]ente.File, error) {
	rows, err := repo.DB.Query(`
		SELECT files.file_id, files.owner_id, collection_files.collection_id, collection_files.c_owner_id,
			collection_files.encrypted_key, collection_files.key_decryption_nonce,
			files.file_decryption_header, files.thumbnail_decryption_header,
			files.metadata_decryption_header, files.encrypted_metadata, files.magic_metadata, files.pub_magic_metadata,
			files.info, collection_files.is_deleted, collection_files.updation_time
		FROM files
		INNER JOIN collection_files
		ON collection_files.file_id = files.file_id
			AND collection_files.collection_id = $1
			AND collection_files.file_id = $2`,
		collectionID, fileID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	files, err := convertRowsToFiles(rows)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return files, nil
}

// GetSharees returns the list of users a collection has been shared with
func (repo *CollectionRepository) GetSharees(cID int64) ([]ente.CollectionUser, error) {
	rows, err := repo.DB.Query(`
		SELECT users.user_id, users.encrypted_email, users.email_decryption_nonce, collection_shares.role_type
		FROM users
		INNER JOIN collection_shares
		ON (collection_shares.collection_id = $1 AND collection_shares.to_user_id = users.user_id AND collection_shares.is_deleted = $2 AND users.encrypted_email IS NOT NULL)`,
		cID, false)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer rows.Close()

	users := make([]ente.CollectionUser, 0)
	for rows.Next() {
		var user ente.CollectionUser
		var encryptedEmail, nonce []byte
		if err := rows.Scan(&user.ID, &encryptedEmail, &nonce, &user.Role); err != nil {
			return users, stacktrace.Propagate(err, "")
		}
		email, err := crypto.Decrypt(encryptedEmail, repo.SecretEncryptionKey, nonce)
		if err != nil {
			return users, stacktrace.Propagate(err, "")
		}
		user.Email = email
		users = append(users, user)
	}
	return users, nil
}

// GetCollectionFileIDs return list of fileIDs are  currently present in the given collection
// and fileIDs are owned by the collection owner
func (repo *CollectionRepository) GetCollectionFileIDs(collectionID int64, collectionOwnerID int64) ([]int64, error) {
	// Collaboration Todo: Filter out files which are not owned by the collection owner
	rows, err := repo.DB.Query(
		`SELECT file_id   
			FROM collection_files
			WHERE is_deleted=false
				AND collection_id =$1 AND (f_owner_id is null or f_owner_id = $2)`, collectionID, collectionOwnerID)
	if err != nil {
		return make([]int64, 0), stacktrace.Propagate(err, "")
	}
	return convertRowsToFileId(rows)
}

func convertRowsToFileId(rows *sql.Rows) ([]int64, error) {
	fileIDs := make([]int64, 0)
	defer rows.Close()
	for rows.Next() {
		var fileID int64
		if err := rows.Scan(&fileID); err != nil {
			return fileIDs, stacktrace.Propagate(err, "")
		}
		fileIDs = append(fileIDs, fileID)
	}
	return fileIDs, nil
}

// TrashV3  move the files belonging to the collection owner to the trash
func (repo *CollectionRepository) TrashV3(ctx context.Context, collectionID int64) error {
	log := logrus.WithFields(logrus.Fields{
		"deleting_collection": collectionID,
	})
	collection, err := repo.Get(collectionID)
	if err != nil {
		log.WithError(err).Error("failed to get collection")
		return stacktrace.Propagate(err, "")
	}
	ownerID := collection.Owner.ID
	fileIDs, err := repo.GetCollectionFileIDs(collectionID, ownerID)
	if err != nil {
		log.WithError(err).Error("failed to get fileIDs")
		return stacktrace.Propagate(err, "")
	}
	log.WithField("file_count", len(fileIDs)).Info("Fetched fileIDs")
	batchSize := 2000
	for i := 0; i < len(fileIDs); i += batchSize {
		end := i + batchSize
		if end > len(fileIDs) {
			end = len(fileIDs)
		}
		batch := fileIDs[i:end]
		err := repo.FileRepo.VerifyFileOwner(ctx, batch, ownerID, log)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		items := make([]ente.TrashItemRequest, 0)
		for _, fileID := range batch {
			items = append(items, ente.TrashItemRequest{
				FileID:       fileID,
				CollectionID: collectionID,
			})
		}
		err = repo.TrashRepo.TrashFiles(fileIDs, ownerID, ente.TrashRequest{OwnerID: ownerID, TrashItems: items})
		if err != nil {
			log.WithError(err).Error("failed to trash file")
			return stacktrace.Propagate(err, "")
		}
	}
	// Verify that all files are processed in the collection.
	count, err := repo.GetCollectionsFilesCount(collectionID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if count != 0 {
		removedFiles, removeErr := repo.removeAllFilesAddedByOthers(collectionID)
		if removeErr != nil {
			return stacktrace.Propagate(removeErr, "")
		}
		if count != removedFiles {
			return fmt.Errorf("investigate: collection %d still has %d files which are not deleted", collectionID, removedFiles-count)
		} else {
			logrus.WithField("collection_id", collectionID).
				WithField("file_count", count).
				WithField("removed_files", removedFiles).
				Info("All files are removed from the collection")
			return nil
		}
	}
	return nil
}

func (repo *CollectionRepository) removeAllFilesAddedByOthers(collectionID int64) (int64, error) {
	var fileIDs []int64
	rows, err := repo.DB.Query(`SELECT file_id FROM collection_files WHERE collection_id = $1 AND is_deleted=false AND f_owner_id IS NOT NULL AND c_owner_id IS NOT NULL AND f_owner_id <> c_owner_id`, collectionID)
	if err != nil {
		return 0, stacktrace.Propagate(err, "")
	}
	defer rows.Close()
	for rows.Next() {
		var fileID int64
		if err := rows.Scan(&fileID); err != nil {
			return 0, stacktrace.Propagate(err, "")
		}
		fileIDs = append(fileIDs, fileID)
	}
	if len(fileIDs) == 0 {
		return 0, nil
	}
	removeErr := repo.RemoveFilesV3(context.Background(), collectionID, fileIDs)
	if removeErr != nil {
		return 0, stacktrace.Propagate(removeErr, "")
	}
	return int64(len(fileIDs)), nil
}

// ScheduleDelete marks the collection as deleted and queue up an operation to
// move the collection files to user's trash.
// See [Collection Delete Versions] for more details
func (repo *CollectionRepository) ScheduleDelete(collectionID int64) error {
	updationTime := time.Microseconds()
	ctx := context.Background()
	tx, err := repo.DB.BeginTx(ctx, nil)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	_, err = tx.ExecContext(ctx, `UPDATE collection_shares 
		SET is_deleted = $1, updation_time = $2 
		WHERE collection_id = $3`, true, updationTime, collectionID)
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	_, err = tx.ExecContext(ctx, `UPDATE collections 
		SET is_deleted = $1, updation_time = $2 
		WHERE collection_id = $3`, true, updationTime, collectionID)
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	err = repo.QueueRepo.AddItems(ctx, tx, TrashCollectionQueueV3, []string{strconv.FormatInt(collectionID, 10)})
	if err != nil {
		tx.Rollback()
		return stacktrace.Propagate(err, "")
	}
	err = tx.Commit()
	return stacktrace.Propagate(err, "")
}

// Rename updates the collection's name by updating the encrypted_name and name_decryption_nonce of the collection
func (repo *CollectionRepository) Rename(collectionID int64, encryptedName string, nameDecryptionNonce string) error {
	updationTime := time.Microseconds()
	_, err := repo.DB.Exec(`UPDATE collections 
				SET encrypted_name = $1,
					name_decryption_nonce=$2,
					updation_time=$3
				WHERE collection_id = $4`,
		encryptedName, nameDecryptionNonce, updationTime, collectionID)
	return stacktrace.Propagate(err, "")
}

// UpdateMagicMetadata updates the magic metadata for the given collection
func (repo *CollectionRepository) UpdateMagicMetadata(ctx context.Context,
	collectionID int64,
	magicMetadata ente.MagicMetadata,
	isPublicMetadata bool,
) error {
	updationTime := time.Microseconds()
	magicMetadata.Version = magicMetadata.Version + 1
	var err error
	if isPublicMetadata {
		_, err = repo.DB.ExecContext(ctx, `UPDATE collections
    				SET pub_magic_metadata = $1,
    				    updation_time=$2
					WHERE collection_id = $3`,
			magicMetadata, updationTime, collectionID)
	} else {
		_, err = repo.DB.ExecContext(ctx, `UPDATE collections 
				SET magic_metadata = $1,
					updation_time=$2
				WHERE collection_id = $3`,
			magicMetadata, updationTime, collectionID)
	}
	return stacktrace.Propagate(err, "")
}

func (repo *CollectionRepository) GetSharedCollectionsCount(userID int64) (int64, error) {
	row := repo.DB.QueryRow(`SELECT count(*) FROM collection_shares WHERE from_user_id = $1`, userID)
	var count int64 = 0
	err := row.Scan(&count)
	if err != nil {
		return -1, stacktrace.Propagate(err, "")
	}
	return count, nil
}

func (repo *CollectionRepository) GetCollectionCount(fileID int64) (int64, error) {
	row := repo.DB.QueryRow(`SELECT count(*) FROM collection_files WHERE file_id = $1 and is_deleted = false`, fileID)
	var count int64 = 0
	err := row.Scan(&count)
	if err != nil {
		return -1, stacktrace.Propagate(err, "")
	}
	return count, nil
}
