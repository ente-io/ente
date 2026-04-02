package contact

import (
	"context"
	"database/sql"
	"errors"

	"github.com/ente-io/museum/ente"
	contactmodel "github.com/ente-io/museum/ente/contact"
	"github.com/ente-io/stacktrace"
	"github.com/lib/pq"
)

func (r *Repository) CanCreateContact(ctx context.Context, actorUserID int64, contactUserID int64) (bool, error) {
	eligible, err := r.hasActiveEmergencyRelationship(ctx, actorUserID, contactUserID)
	if err != nil {
		return false, stacktrace.Propagate(err, "failed to check emergency relationship")
	}
	if eligible {
		return true, nil
	}

	eligible, err = r.hasSharedActiveFamily(ctx, actorUserID, contactUserID)
	if err != nil {
		return false, stacktrace.Propagate(err, "failed to check family relationship")
	}
	if eligible {
		return true, nil
	}

	eligible, err = r.hasCommonSharedCollection(ctx, actorUserID, contactUserID)
	if err != nil {
		return false, stacktrace.Propagate(err, "failed to check shared collections")
	}
	return eligible, nil
}

func (r *Repository) Create(ctx context.Context, userID int64, req contactmodel.CreateRequest) (string, error) {
	id := contactmodel.NewContactID()
	err := r.DB.QueryRowContext(
		ctx,
		`INSERT INTO contact_entity(id, user_id, contact_user_id, encrypted_key, encrypted_data)
		 VALUES($1, $2, $3, $4, $5)
		 RETURNING id`,
		id,
		userID,
		req.ContactUserID,
		req.EncryptedKey,
		req.EncryptedData,
	).Scan(&id)
	if err != nil {
		var pqErr *pq.Error
		if errors.As(err, &pqErr) && pqErr.Code == "23505" {
			return "", stacktrace.Propagate(
				ente.NewBadRequestWithMessage("contact already exists for contactUserID"),
				"",
			)
		}
		return "", stacktrace.Propagate(err, "failed to create contact")
	}
	return id, nil
}

func (r *Repository) hasActiveEmergencyRelationship(ctx context.Context, actorUserID int64, contactUserID int64) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(
		ctx,
		`SELECT EXISTS(
			SELECT 1
			FROM emergency_contact
			WHERE state = ANY($3)
			  AND (
					(user_id = $1 AND emergency_contact_id = $2)
				 OR (user_id = $2 AND emergency_contact_id = $1)
			  )
		)`,
		actorUserID,
		contactUserID,
		pq.Array([]ente.ContactState{ente.UserInvitedContact, ente.ContactAccepted}),
	).Scan(&exists)
	if err != nil {
		return false, err
	}
	return exists, nil
}

func (r *Repository) hasSharedActiveFamily(ctx context.Context, actorUserID int64, contactUserID int64) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(
		ctx,
		`SELECT EXISTS(
			SELECT 1
			FROM users actor
			JOIN users contact ON actor.family_admin_id = contact.family_admin_id
			WHERE actor.user_id = $1
			  AND contact.user_id = $2
			  AND actor.family_admin_id IS NOT NULL
		)`,
		actorUserID,
		contactUserID,
	).Scan(&exists)
	if err != nil {
		return false, err
	}
	return exists, nil
}

func (r *Repository) hasCommonSharedCollection(ctx context.Context, actorUserID int64, contactUserID int64) (bool, error) {
	var exists bool
	err := r.DB.QueryRowContext(
		ctx,
		`WITH shared_access AS (
			SELECT collection_id
			FROM collection_shares
			WHERE collection_shares.is_deleted = FALSE
			  AND (collection_shares.to_user_id = $1 OR collection_shares.from_user_id = $1)
		), contact_shared_access AS (
			SELECT collection_id
			FROM collection_shares
			WHERE collection_shares.is_deleted = FALSE
			  AND (collection_shares.to_user_id = $2 OR collection_shares.from_user_id = $2)
		)
		SELECT EXISTS(
			SELECT 1
			FROM shared_access actor
			INNER JOIN contact_shared_access contact
				ON actor.collection_id = contact.collection_id
		)`,
		actorUserID,
		contactUserID,
	).Scan(&exists)
	if err != nil {
		return false, err
	}
	return exists, nil
}

func (r *Repository) Get(ctx context.Context, userID int64, id string) (*contactmodel.Entity, error) {
	row := r.DB.QueryRowContext(
		ctx,
		`SELECT id, user_id, contact_user_id, profile_picture_attachment_id, encrypted_key, encrypted_data,
		        is_deleted, created_at, updated_at
		   FROM contact_entity
		  WHERE id = $1 AND user_id = $2`,
		id,
		userID,
	)
	entity, err := scanEntity(row)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, &ente.ErrNotFoundError
		}
		return nil, stacktrace.Propagate(err, "failed to get contact")
	}
	return entity, nil
}

func (r *Repository) Update(ctx context.Context, userID int64, id string, req contactmodel.UpdateRequest) error {
	result, err := r.DB.ExecContext(
		ctx,
		`UPDATE contact_entity
		    SET contact_user_id = $1, encrypted_data = $2
		  WHERE id = $3 AND user_id = $4 AND is_deleted = FALSE`,
		req.ContactUserID,
		req.EncryptedData,
		id,
		userID,
	)
	if err != nil {
		var pqErr *pq.Error
		if errors.As(err, &pqErr) && pqErr.Code == "23505" {
			return stacktrace.Propagate(
				ente.NewBadRequestWithMessage("contact already exists for contactUserID"),
				"",
			)
		}
		return stacktrace.Propagate(err, "failed to update contact")
	}
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if rowsAffected == 1 {
		return nil
	}
	entity, getErr := r.Get(ctx, userID, id)
	if getErr != nil {
		return stacktrace.Propagate(getErr, "failed to fetch contact after update miss")
	}
	if entity.IsDeleted {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage("contact is already deleted"), "")
	}
	return stacktrace.NewError("exactly one row should be updated")
}

func (r *Repository) Delete(ctx context.Context, userID int64, id string) error {
	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	defer tx.Rollback()

	entity, err := r.getForUpdate(ctx, tx, userID, id)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if entity.IsDeleted {
		return tx.Commit()
	}

	if entity.ProfilePictureAttachmentID != nil {
		if err := markAttachmentDeletedTx(ctx, tx, userID, *entity.ProfilePictureAttachmentID); err != nil {
			return stacktrace.Propagate(err, "")
		}
	}
	if _, err := tx.ExecContext(
		ctx,
		`UPDATE contact_entity
		    SET is_deleted = TRUE,
		        encrypted_data = NULL,
		        profile_picture_attachment_id = NULL
		  WHERE id = $1 AND user_id = $2`,
		id,
		userID,
	); err != nil {
		return stacktrace.Propagate(err, "failed to delete contact")
	}
	return stacktrace.Propagate(tx.Commit(), "")
}

func (r *Repository) GetDiff(ctx context.Context, userID int64, sinceTime int64, limit int16) ([]contactmodel.Entity, error) {
	rows, err := r.DB.QueryContext(
		ctx,
		`SELECT id, user_id, contact_user_id, profile_picture_attachment_id, encrypted_key, encrypted_data,
		        is_deleted, created_at, updated_at
		   FROM contact_entity
		  WHERE user_id = $1 AND updated_at > $2
		  ORDER BY updated_at
		  LIMIT $3`,
		userID,
		sinceTime,
		limit,
	)
	if err != nil {
		return nil, stacktrace.Propagate(err, "contact diff query failed")
	}
	defer rows.Close()

	entities := make([]contactmodel.Entity, 0)
	for rows.Next() {
		entity, scanErr := scanEntity(rows)
		if scanErr != nil {
			return nil, stacktrace.Propagate(scanErr, "failed to scan contact diff row")
		}
		entities = append(entities, *entity)
	}
	return entities, nil
}

func (r *Repository) AttachProfilePicture(ctx context.Context, userID int64, contactID string, attachmentID string, size int64) (*contactmodel.Entity, error) {
	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer tx.Rollback()

	entity, err := r.getForUpdate(ctx, tx, userID, contactID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if entity.IsDeleted {
		return nil, stacktrace.Propagate(ente.NewBadRequestWithMessage("contact is already deleted"), "")
	}

	objectKey := contactmodel.AttachmentObjectKey(userID, contactmodel.ProfilePicture, attachmentID)
	var latestBucket string
	if err := tx.QueryRowContext(
		ctx,
		`SELECT bucket_id FROM temp_objects WHERE object_key = $1 FOR UPDATE`,
		objectKey,
	).Scan(&latestBucket); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, stacktrace.Propagate(ente.NewBadRequestWithMessage("staged profile picture upload not found"), "")
		}
		return nil, stacktrace.Propagate(err, "failed to fetch staged profile picture")
	}

	if _, err := tx.ExecContext(
		ctx,
		`INSERT INTO user_attachments(attachment_id, user_id, attachment_type, size, latest_bucket)
		 VALUES($1, $2, $3, $4, $5)`,
		attachmentID,
		userID,
		string(contactmodel.ProfilePicture),
		size,
		latestBucket,
	); err != nil {
		var pqErr *pq.Error
		if errors.As(err, &pqErr) && pqErr.Code == "23505" {
			return nil, stacktrace.Propagate(ente.NewBadRequestWithMessage("attachmentID already exists"), "")
		}
		return nil, stacktrace.Propagate(err, "failed to insert attachment row")
	}

	if entity.ProfilePictureAttachmentID != nil && *entity.ProfilePictureAttachmentID != "" {
		if err := markAttachmentDeletedTx(ctx, tx, userID, *entity.ProfilePictureAttachmentID); err != nil {
			return nil, stacktrace.Propagate(err, "")
		}
	}

	if _, err := tx.ExecContext(
		ctx,
		`UPDATE contact_entity
		    SET profile_picture_attachment_id = $1
		  WHERE id = $2 AND user_id = $3 AND is_deleted = FALSE`,
		attachmentID,
		contactID,
		userID,
	); err != nil {
		return nil, stacktrace.Propagate(err, "failed to update contact profile picture")
	}

	if err := r.ObjectCleanupRepo.RemoveTempObjectFromDC(ctx, tx, objectKey, latestBucket); err != nil {
		return nil, stacktrace.Propagate(err, "failed to remove profile picture from temp_objects")
	}

	if err := tx.Commit(); err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return r.Get(ctx, userID, contactID)
}

func (r *Repository) DeleteProfilePicture(ctx context.Context, userID int64, contactID string) (*contactmodel.Entity, error) {
	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer tx.Rollback()

	entity, err := r.getForUpdate(ctx, tx, userID, contactID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if entity.IsDeleted {
		return nil, stacktrace.Propagate(ente.NewBadRequestWithMessage("contact is already deleted"), "")
	}
	if entity.ProfilePictureAttachmentID != nil {
		if err := markAttachmentDeletedTx(ctx, tx, userID, *entity.ProfilePictureAttachmentID); err != nil {
			return nil, stacktrace.Propagate(err, "")
		}
		if _, err := tx.ExecContext(
			ctx,
			`UPDATE contact_entity
			    SET profile_picture_attachment_id = NULL
			  WHERE id = $1 AND user_id = $2 AND is_deleted = FALSE`,
			contactID,
			userID,
		); err != nil {
			return nil, stacktrace.Propagate(err, "failed to clear contact profile picture")
		}
	}
	if err := tx.Commit(); err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return r.Get(ctx, userID, contactID)
}

func (r *Repository) GetAttachment(ctx context.Context, userID int64, attachmentID string) (*contactmodel.Attachment, error) {
	row := r.DB.QueryRowContext(
		ctx,
		`SELECT attachment_id, user_id, attachment_type, size, latest_bucket, replicated_buckets,
		        delete_from_buckets, inflight_rep_buckets, pending_sync, is_deleted, sync_locked_till,
		        created_at, updated_at
		   FROM user_attachments
		  WHERE attachment_id = $1 AND user_id = $2`,
		attachmentID,
		userID,
	)
	attachment, err := scanAttachment(row)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, &ente.ErrNotFoundError
		}
		return nil, stacktrace.Propagate(err, "failed to get attachment")
	}
	return attachment, nil
}

func (r *Repository) getForUpdate(ctx context.Context, tx *sql.Tx, userID int64, id string) (*contactmodel.Entity, error) {
	row := tx.QueryRowContext(
		ctx,
		`SELECT id, user_id, contact_user_id, profile_picture_attachment_id, encrypted_key, encrypted_data,
		        is_deleted, created_at, updated_at
		   FROM contact_entity
		  WHERE id = $1 AND user_id = $2
		  FOR UPDATE`,
		id,
		userID,
	)
	entity, err := scanEntity(row)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, &ente.ErrNotFoundError
		}
		return nil, stacktrace.Propagate(err, "failed to lock contact row")
	}
	return entity, nil
}

func markAttachmentDeletedTx(ctx context.Context, tx *sql.Tx, userID int64, attachmentID string) error {
	_, err := tx.ExecContext(
		ctx,
		`UPDATE user_attachments
		    SET is_deleted = TRUE,
		        pending_sync = TRUE,
		        sync_locked_till = 0,
		        delete_from_buckets = array(
		            SELECT DISTINCT elem
		              FROM unnest(array_cat(array_cat(replicated_buckets, delete_from_buckets), inflight_rep_buckets)) AS elem
		             WHERE elem IS NOT NULL
		        ),
		        replicated_buckets = ARRAY[]::s3region[],
		        inflight_rep_buckets = ARRAY[]::s3region[]
		  WHERE attachment_id = $1
		    AND user_id = $2
		    AND attachment_type = $3
		    AND is_deleted = FALSE`,
		attachmentID,
		userID,
		string(contactmodel.ProfilePicture),
	)
	return stacktrace.Propagate(err, "failed to mark attachment deleted")
}

type rowScanner interface {
	Scan(dest ...interface{}) error
}

func scanEntity(scanner rowScanner) (*contactmodel.Entity, error) {
	var (
		entity        contactmodel.Entity
		pictureID     sql.NullString
		encryptedKey  []byte
		encryptedData []byte
	)
	if err := scanner.Scan(
		&entity.ID,
		&entity.UserID,
		&entity.ContactUserID,
		&pictureID,
		&encryptedKey,
		&encryptedData,
		&entity.IsDeleted,
		&entity.CreatedAt,
		&entity.UpdatedAt,
	); err != nil {
		return nil, err
	}
	if pictureID.Valid {
		entity.ProfilePictureAttachmentID = &pictureID.String
	}
	if entity.IsDeleted {
		entity.ProfilePictureAttachmentID = nil
		entity.EncryptedKey = nil
		entity.EncryptedData = nil
		return &entity, nil
	}
	entity.EncryptedKey = &encryptedKey
	entity.EncryptedData = &encryptedData
	return &entity, nil
}

func scanAttachment(scanner rowScanner) (*contactmodel.Attachment, error) {
	var attachment contactmodel.Attachment
	if err := scanner.Scan(
		&attachment.AttachmentID,
		&attachment.UserID,
		&attachment.AttachmentType,
		&attachment.Size,
		&attachment.LatestBucket,
		pq.Array(&attachment.ReplicatedBuckets),
		pq.Array(&attachment.DeleteFromBuckets),
		pq.Array(&attachment.InflightRepBuckets),
		&attachment.PendingSync,
		&attachment.IsDeleted,
		&attachment.SyncLockedTill,
		&attachment.CreatedAt,
		&attachment.UpdatedAt,
	); err != nil {
		return nil, err
	}
	return &attachment, nil
}
