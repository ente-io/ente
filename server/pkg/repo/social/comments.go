package social

import (
	"context"
	"database/sql"

	"github.com/ente-io/museum/ente"
	socialentity "github.com/ente-io/museum/ente/social"
	"github.com/ente-io/stacktrace"
	"github.com/lib/pq"
)

// CommentsRepository manages comment records.
type CommentsRepository struct {
	DB *sql.DB
}

func (repo *CommentsRepository) Insert(ctx context.Context, comment socialentity.Comment) error {
	_, err := repo.DB.ExecContext(ctx, `
        INSERT INTO comments (id, collection_id, file_id, parent_comment_id, user_id, anon_user_id, cipher, nonce, is_deleted)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
    `,
		comment.ID,
		comment.CollectionID,
		comment.FileID,
		comment.ParentCommentID,
		comment.UserID,
		comment.AnonUserID,
		comment.Cipher,
		comment.Nonce,
		false,
	)
	return stacktrace.Propagate(err, "")
}

func (repo *CommentsRepository) UpdateCipher(ctx context.Context, id string, cipher string, nonce string) error {
	result, err := repo.DB.ExecContext(ctx, `
        UPDATE comments
        SET cipher = $1,
            nonce = $2,
            updated_at = now_utc_micro_seconds()
        WHERE id = $3
          AND is_deleted = FALSE
    `, cipher, nonce, id)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	rows, err := result.RowsAffected()
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if rows == 0 {
		return stacktrace.Propagate(ente.ErrNotFound, "")
	}
	return nil
}

func (repo *CommentsRepository) SoftDelete(ctx context.Context, id string) error {
	result, err := repo.DB.ExecContext(ctx, `
        UPDATE comments
        SET is_deleted = TRUE,
            cipher = NULL,
            nonce = NULL,
            updated_at = now_utc_micro_seconds()
        WHERE id = $1
          AND is_deleted = FALSE
    `, id)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	rows, err := result.RowsAffected()
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if rows == 0 {
		return stacktrace.Propagate(ente.ErrNotFound, "")
	}
	return nil
}

func (repo *CommentsRepository) GetByID(ctx context.Context, id string) (*socialentity.Comment, error) {
	var (
		fileID sql.NullInt64
		parent sql.NullString
		anon   sql.NullString
		cipher sql.NullString
		nonce  sql.NullString
	)
	comment := &socialentity.Comment{}
	err := repo.DB.QueryRowContext(ctx, `
        SELECT id, collection_id, file_id, parent_comment_id, user_id, anon_user_id, cipher, nonce, is_deleted, created_at, updated_at
        FROM comments
        WHERE id = $1
    `, id).Scan(
		&comment.ID,
		&comment.CollectionID,
		&fileID,
		&parent,
		&comment.UserID,
		&anon,
		&cipher,
		&nonce,
		&comment.IsDeleted,
		&comment.CreatedAt,
		&comment.UpdatedAt,
	)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if fileID.Valid {
		comment.FileID = &fileID.Int64
	}
	if parent.Valid {
		comment.ParentCommentID = &parent.String
	}
	if anon.Valid {
		comment.AnonUserID = &anon.String
	}
	if cipher.Valid {
		comment.Cipher = cipher.String
	}
	if nonce.Valid {
		comment.Nonce = nonce.String
	}
	return comment, nil
}

func (repo *CommentsRepository) GetDiff(ctx context.Context, collectionID int64, since int64, limit int, fileID *int64) ([]socialentity.Comment, bool, error) {
	query := `
        SELECT id, collection_id, file_id, parent_comment_id, user_id, anon_user_id, cipher, nonce, is_deleted, created_at, updated_at
        FROM comments
        WHERE collection_id = $1
          AND updated_at > $2
          AND ($3 IS NULL OR file_id IS NOT DISTINCT FROM $3)
        ORDER BY updated_at ASC
        LIMIT $4
    `
	rows, err := repo.DB.QueryContext(ctx, query, collectionID, since, fileID, limit+1)
	if err != nil {
		return nil, false, stacktrace.Propagate(err, "")
	}
	defer rows.Close()

	comments := make([]socialentity.Comment, 0, limit+1)
	for rows.Next() {
		var (
			file    sql.NullInt64
			parent  sql.NullString
			anon    sql.NullString
			cipher  sql.NullString
			nonce   sql.NullString
			comment socialentity.Comment
		)
		if err := rows.Scan(
			&comment.ID,
			&comment.CollectionID,
			&file,
			&parent,
			&comment.UserID,
			&anon,
			&cipher,
			&nonce,
			&comment.IsDeleted,
			&comment.CreatedAt,
			&comment.UpdatedAt,
		); err != nil {
			return nil, false, stacktrace.Propagate(err, "")
		}
		if file.Valid {
			comment.FileID = &file.Int64
		}
		if parent.Valid {
			comment.ParentCommentID = &parent.String
		}
		if anon.Valid {
			comment.AnonUserID = &anon.String
		}
		if cipher.Valid {
			comment.Cipher = cipher.String
		}
		if nonce.Valid {
			comment.Nonce = nonce.String
		}
		comments = append(comments, comment)
	}
	if err := rows.Err(); err != nil {
		return nil, false, stacktrace.Propagate(err, "")
	}

	hasMore := false
	if len(comments) > limit {
		hasMore = true
		comments = comments[:limit]
	}
	return comments, hasMore, nil
}

func (repo *CommentsRepository) CountActiveByCollection(ctx context.Context, collectionIDs []int64) (map[int64]int64, error) {
	counts := make(map[int64]int64)
	if len(collectionIDs) == 0 {
		return counts, nil
	}
	rows, err := repo.DB.QueryContext(ctx, `
        SELECT collection_id, COUNT(*)
        FROM comments
        WHERE collection_id = ANY($1)
          AND is_deleted = FALSE
        GROUP BY collection_id
    `, pq.Array(collectionIDs))
	if err != nil {
		return counts, stacktrace.Propagate(err, "")
	}
	defer rows.Close()
	for rows.Next() {
		var collectionID int64
		var count int64
		if err := rows.Scan(&collectionID, &count); err != nil {
			return counts, stacktrace.Propagate(err, "")
		}
		counts[collectionID] = count
	}
	if err := rows.Err(); err != nil {
		return counts, stacktrace.Propagate(err, "")
	}
	return counts, nil
}

func (repo *CommentsRepository) GetActiveUserIDs(ctx context.Context, collectionID int64) ([]int64, error) {
	rows, err := repo.DB.QueryContext(ctx, `
        SELECT DISTINCT user_id
        FROM comments
        WHERE collection_id = $1
          AND user_id > 0
          AND is_deleted = FALSE
    `, collectionID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	defer rows.Close()
	ids := make([]int64, 0)
	for rows.Next() {
		var id int64
		if err := rows.Scan(&id); err != nil {
			return nil, stacktrace.Propagate(err, "")
		}
		ids = append(ids, id)
	}
	if err := rows.Err(); err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return ids, nil
}
