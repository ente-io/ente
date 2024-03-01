package locationtag

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

// Repository defines the methods for inserting, updating and retrieving
// locationTag related entities from the underlying repository
type Repository struct {
	DB *sql.DB
}

// Create inserts a new &{ente.LocationTag} entry
func (r *Repository) Create(ctx context.Context, locationTag ente.LocationTag) (ente.LocationTag, error) {
	err := r.DB.QueryRow(`INSERT into location_tag(
                         id,
                         user_id,
                         encrypted_key,
                         key_decryption_nonce,
                         attributes) VALUES ($1,$2,$3,$4,$5) RETURNING id,created_at,updated_at`,
		uuid.New(),                     //$1 id
		locationTag.OwnerID,            // $2 user_id
		locationTag.EncryptedKey,       // $3 encrypted_key
		locationTag.KeyDecryptionNonce, // $4 key_decryption_nonce
		locationTag.Attributes).        // %5 attributes
		Scan(&locationTag.ID, &locationTag.CreatedAt, &locationTag.UpdatedAt)
	if err != nil {
		return ente.LocationTag{}, stacktrace.Propagate(err, "Failed to create locationTag")
	}
	return locationTag, nil
}

// GetDiff returns the &{[]ente.LocationTag} which have been added or
// modified after the given sinceTime
func (r *Repository) GetDiff(ctx context.Context, ownerID int64, sinceTime int64, limit int16) ([]ente.LocationTag, error) {
	rows, err := r.DB.Query(`SELECT
       id, user_id, provider, encrypted_key, key_decryption_nonce,
       attributes, is_deleted, created_at, updated_at
	   FROM location_tag
	   WHERE user_id = $1
	   and updated_at > $2
       ORDER BY updated_at
	   LIMIT $3`,
		ownerID,   // $1
		sinceTime, // %2
		limit,     // $3
	)
	if err != nil {
		return nil, stacktrace.Propagate(err, "GetDiff query failed")
	}
	return convertRowsToLocationTags(rows)
}

func (r *Repository) Delete(ctx context.Context, id string, ownerID int64) (bool, error) {
	_, err := r.DB.ExecContext(ctx,
		`UPDATE location_tag SET is_deleted=$1, attributes=$2 where id=$3 and user_id = $4`,
		true, `{}`, // $1 is_deleted, $2 attr
		id, ownerID) // $3 tagId, $4 ownerID
	if err != nil {
		return false, stacktrace.Propagate(err, fmt.Sprintf("faield to delele tag with id=%s", id))
	}
	return true, nil
}

func convertRowsToLocationTags(rows *sql.Rows) ([]ente.LocationTag, error) {
	defer func() {
		if err := rows.Close(); err != nil {
			logrus.Error(err)
		}
	}()
	locationTags := make([]ente.LocationTag, 0)
	for rows.Next() {
		tag := ente.LocationTag{}
		err := rows.Scan(
			&tag.ID, &tag.OwnerID, &tag.Provider, &tag.EncryptedKey, &tag.KeyDecryptionNonce,
			&tag.Attributes, &tag.IsDeleted, &tag.CreatedAt, &tag.UpdatedAt)
		if err != nil {
			return nil, stacktrace.Propagate(err, "Failed to convert rowToLocationTag")
		}
		locationTags = append(locationTags, tag)
	}
	return locationTags, nil
}
