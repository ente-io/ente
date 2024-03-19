package embedding

import (
	"context"
	"database/sql"
	"fmt"
	"github.com/lib/pq"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
	"github.com/sirupsen/logrus"
)

// Repository defines the methods for inserting, updating and retrieving
// ML embedding
type Repository struct {
	DB *sql.DB
}

// Create inserts a new embedding

func (r *Repository) InsertOrUpdate(ctx context.Context, ownerID int64, entry ente.InsertOrUpdateEmbeddingRequest, size int, version int) (ente.Embedding, error) {
	var updatedAt int64
	err := r.DB.QueryRowContext(ctx, `INSERT INTO embeddings 
								(file_id, owner_id, model, size, version) 
								VALUES ($1, $2, $3, $4, $5)
								ON CONFLICT ON CONSTRAINT unique_embeddings_file_id_model
								DO UPDATE SET updated_at = now_utc_micro_seconds(), size = $4, version = $5
								RETURNING updated_at`, entry.FileID, ownerID, entry.Model, size, version).Scan(&updatedAt)
	if err != nil {
		// check if error is due to model enum invalid value
		if err.Error() == fmt.Sprintf("pq: invalid input value for enum model: \"%s\"", entry.Model) {
			return ente.Embedding{}, stacktrace.Propagate(ente.ErrBadRequest, "invalid model value")
		}
		return ente.Embedding{}, stacktrace.Propagate(err, "")
	}
	return ente.Embedding{
		FileID:             entry.FileID,
		Model:              entry.Model,
		EncryptedEmbedding: entry.EncryptedEmbedding,
		DecryptionHeader:   entry.DecryptionHeader,
		UpdatedAt:          updatedAt,
	}, nil
}

// GetDiff returns the embeddings that have been updated since the given time
func (r *Repository) GetDiff(ctx context.Context, ownerID int64, model ente.Model, sinceTime int64, limit int16) ([]ente.Embedding, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT file_id, model, encrypted_embedding, decryption_header, updated_at, version
										FROM embeddings
										WHERE owner_id = $1 AND model = $2 AND updated_at > $3
										ORDER BY updated_at ASC
										LIMIT $4`, ownerID, model, sinceTime, limit)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return convertRowsToEmbeddings(rows)
}

func (r *Repository) GetFilesEmbedding(ctx context.Context, ownerID int64, model ente.Model, fileIDs []int64) ([]ente.Embedding, error) {
	rows, err := r.DB.QueryContext(ctx, `SELECT file_id, model, encrypted_embedding, decryption_header, updated_at, version
										FROM embeddings
										WHERE owner_id = $1 AND model = $2 AND file_id = ANY($3)`, ownerID, model, pq.Array(fileIDs))
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return convertRowsToEmbeddings(rows)
}

func (r *Repository) DeleteAll(ctx context.Context, ownerID int64) error {
	_, err := r.DB.ExecContext(ctx, "DELETE FROM embeddings WHERE owner_id = $1", ownerID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

func (r *Repository) Delete(fileID int64) error {
	_, err := r.DB.Exec("DELETE FROM embeddings WHERE file_id = $1", fileID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

func convertRowsToEmbeddings(rows *sql.Rows) ([]ente.Embedding, error) {
	defer func() {
		if err := rows.Close(); err != nil {
			logrus.Error(err)
		}
	}()

	result := make([]ente.Embedding, 0)
	for rows.Next() {
		embedding := ente.Embedding{}
		var encryptedEmbedding, decryptionHeader sql.NullString
		var version sql.NullInt32
		err := rows.Scan(&embedding.FileID, &embedding.Model, &encryptedEmbedding, &decryptionHeader, &embedding.UpdatedAt, &version)
		if encryptedEmbedding.Valid && len(encryptedEmbedding.String) > 0 {
			embedding.EncryptedEmbedding = encryptedEmbedding.String
		}
		if decryptionHeader.Valid && len(decryptionHeader.String) > 0 {
			embedding.DecryptionHeader = decryptionHeader.String
		}
		v := 1
		if version.Valid {
			v = int(version.Int32)
		}
		embedding.Version = &v
		if err != nil {
			return nil, stacktrace.Propagate(err, "")
		}
		result = append(result, embedding)
	}
	return result, nil
}
