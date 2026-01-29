package repo

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/lib/pq"
	"github.com/spf13/viper"
)

// MemoryShareRepository is an implementation of the repository for memory shares
type MemoryShareRepository struct {
	DB         *sql.DB
	memoryHost string
}

// NewMemoryShareRepository creates a new MemoryShareRepository
func NewMemoryShareRepository(db *sql.DB) *MemoryShareRepository {
	memoryHost := viper.GetString("apps.public-memories")
	if memoryHost == "" {
		memoryHost = "https://memories.ente.io"
	}
	return &MemoryShareRepository{
		DB:         db,
		memoryHost: memoryHost,
	}
}

// GetMemoryShareURL returns the public URL for a memory share
func (r *MemoryShareRepository) GetMemoryShareURL(accessToken string) string {
	return fmt.Sprintf("%s/%s", r.memoryHost, accessToken)
}

// Create creates a new memory share and returns it with the generated ID
func (r *MemoryShareRepository) Create(ctx context.Context, share ente.MemoryShare) (ente.MemoryShare, error) {
	now := time.Microseconds()
	err := r.DB.QueryRowContext(ctx, `
		INSERT INTO memory_shares
		(user_id, type, metadata_cipher, metadata_nonce,
		 mem_enc_key, mem_key_decryption_nonce, access_token, is_deleted, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
		RETURNING id`,
		share.UserID, share.Type, share.MetadataCipher, share.MetadataNonce,
		share.EncryptedKey, share.KeyDecryptionNonce, share.AccessToken,
		false, now, now).Scan(&share.ID)
	if err != nil {
		return share, stacktrace.Propagate(err, "failed to create memory share")
	}
	share.CreatedAt = now
	share.UpdatedAt = now
	share.URL = r.GetMemoryShareURL(share.AccessToken)
	return share, nil
}

// AddFiles adds files to a memory share
func (r *MemoryShareRepository) AddFiles(ctx context.Context, shareID int64, files []ente.MemoryShareFile) error {
	tx, err := r.DB.BeginTx(ctx, nil)
	if err != nil {
		return stacktrace.Propagate(err, "failed to begin transaction")
	}
	defer tx.Rollback()

	now := time.Microseconds()
	for _, file := range files {
		_, err = tx.ExecContext(ctx, `
			INSERT INTO memory_share_files
			(memory_share_id, file_id, file_owner_id, file_enc_key, file_key_decryption_nonce, created_at)
			VALUES ($1, $2, $3, $4, $5, $6)`,
			shareID, file.FileID, file.FileOwnerID, file.EncryptedKey, file.KeyDecryptionNonce, now)
		if err != nil {
			return stacktrace.Propagate(err, "failed to add file to memory share")
		}
	}

	if err = tx.Commit(); err != nil {
		return stacktrace.Propagate(err, "failed to commit transaction")
	}
	return nil
}

// GetByID retrieves a memory share by its ID
func (r *MemoryShareRepository) GetByID(ctx context.Context, id int64) (*ente.MemoryShare, error) {
	share := &ente.MemoryShare{}
	err := r.DB.QueryRowContext(ctx, `
		SELECT id, user_id, type, metadata_cipher, metadata_nonce,
		       mem_enc_key, mem_key_decryption_nonce, access_token, is_deleted, created_at, updated_at
		FROM memory_shares WHERE id = $1`, id).Scan(
		&share.ID, &share.UserID, &share.Type, &share.MetadataCipher, &share.MetadataNonce,
		&share.EncryptedKey, &share.KeyDecryptionNonce, &share.AccessToken,
		&share.IsDeleted, &share.CreatedAt, &share.UpdatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, stacktrace.Propagate(ente.ErrNotFound, "memory share not found")
		}
		return nil, stacktrace.Propagate(err, "failed to get memory share")
	}
	share.URL = r.GetMemoryShareURL(share.AccessToken)
	return share, nil
}

// GetByAccessToken retrieves a memory share by its access token
func (r *MemoryShareRepository) GetByAccessToken(ctx context.Context, token string) (*ente.MemoryShare, error) {
	share := &ente.MemoryShare{}
	err := r.DB.QueryRowContext(ctx, `
		SELECT id, user_id, type, metadata_cipher, metadata_nonce,
		       mem_enc_key, mem_key_decryption_nonce, access_token, is_deleted, created_at, updated_at
		FROM memory_shares WHERE access_token = $1`, token).Scan(
		&share.ID, &share.UserID, &share.Type, &share.MetadataCipher, &share.MetadataNonce,
		&share.EncryptedKey, &share.KeyDecryptionNonce, &share.AccessToken,
		&share.IsDeleted, &share.CreatedAt, &share.UpdatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, stacktrace.Propagate(ente.ErrNotFound, "memory share not found")
		}
		return nil, stacktrace.Propagate(err, "failed to get memory share by token")
	}
	share.URL = r.GetMemoryShareURL(share.AccessToken)
	return share, nil
}

// GetFiles retrieves all files for a memory share
func (r *MemoryShareRepository) GetFiles(ctx context.Context, shareID int64) ([]ente.MemoryShareFile, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, memory_share_id, file_id, file_owner_id, file_enc_key, file_key_decryption_nonce, created_at
		FROM memory_share_files WHERE memory_share_id = $1`, shareID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to get memory share files")
	}
	defer rows.Close()

	var files []ente.MemoryShareFile
	for rows.Next() {
		var file ente.MemoryShareFile
		if err = rows.Scan(&file.ID, &file.MemoryShareID, &file.FileID, &file.FileOwnerID,
			&file.EncryptedKey, &file.KeyDecryptionNonce, &file.CreatedAt); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan memory share file")
		}
		files = append(files, file)
	}
	return files, nil
}

// GetFileIDs retrieves all file IDs for a memory share
func (r *MemoryShareRepository) GetFileIDs(ctx context.Context, shareID int64) ([]int64, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT file_id FROM memory_share_files WHERE memory_share_id = $1`, shareID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to get memory share file IDs")
	}
	defer rows.Close()

	var fileIDs []int64
	for rows.Next() {
		var fileID int64
		if err = rows.Scan(&fileID); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan file ID")
		}
		fileIDs = append(fileIDs, fileID)
	}
	return fileIDs, nil
}

// GetByUserID retrieves all memory shares for a user
func (r *MemoryShareRepository) GetByUserID(ctx context.Context, userID int64) ([]ente.MemoryShare, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, user_id, type, metadata_cipher, metadata_nonce,
		       mem_enc_key, mem_key_decryption_nonce, access_token, is_deleted, created_at, updated_at
		FROM memory_shares WHERE user_id = $1 AND is_deleted = false
		ORDER BY created_at DESC`, userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to get memory shares for user")
	}
	defer rows.Close()

	var shares []ente.MemoryShare
	for rows.Next() {
		var share ente.MemoryShare
		if err = rows.Scan(&share.ID, &share.UserID, &share.Type, &share.MetadataCipher, &share.MetadataNonce,
			&share.EncryptedKey, &share.KeyDecryptionNonce, &share.AccessToken,
			&share.IsDeleted, &share.CreatedAt, &share.UpdatedAt); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan memory share")
		}
		share.URL = r.GetMemoryShareURL(share.AccessToken)
		shares = append(shares, share)
	}
	return shares, nil
}

// Delete soft-deletes a memory share
func (r *MemoryShareRepository) Delete(ctx context.Context, shareID int64, userID int64) error {
	result, err := r.DB.ExecContext(ctx, `
		UPDATE memory_shares SET is_deleted = true, updated_at = $1
		WHERE id = $2 AND user_id = $3 AND is_deleted = false`,
		time.Microseconds(), shareID, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete memory share")
	}
	rowsAffected, err := result.RowsAffected()
	if err != nil {
		return stacktrace.Propagate(err, "failed to get rows affected")
	}
	if rowsAffected == 0 {
		return stacktrace.Propagate(ente.ErrNotFound, "memory share not found or not owned by user")
	}
	return nil
}

// GetFileOwnerMap returns a map of file ID to owner ID for files in a memory share
func (r *MemoryShareRepository) GetFileOwnerMap(ctx context.Context, shareID int64) (map[int64]int64, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT file_id, file_owner_id FROM memory_share_files WHERE memory_share_id = $1`, shareID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to get file owner map")
	}
	defer rows.Close()

	ownerMap := make(map[int64]int64)
	for rows.Next() {
		var fileID, ownerID int64
		if err = rows.Scan(&fileID, &ownerID); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan file owner")
		}
		ownerMap[fileID] = ownerID
	}
	return ownerMap, nil
}

// GetFileByID retrieves a specific file from a memory share
func (r *MemoryShareRepository) GetFileByID(ctx context.Context, shareID int64, fileID int64) (*ente.MemoryShareFile, error) {
	file := &ente.MemoryShareFile{}
	err := r.DB.QueryRowContext(ctx, `
		SELECT id, memory_share_id, file_id, file_owner_id, file_enc_key, file_key_decryption_nonce, created_at
		FROM memory_share_files WHERE memory_share_id = $1 AND file_id = $2`, shareID, fileID).Scan(
		&file.ID, &file.MemoryShareID, &file.FileID, &file.FileOwnerID,
		&file.EncryptedKey, &file.KeyDecryptionNonce, &file.CreatedAt)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, stacktrace.Propagate(ente.ErrNotFound, "file not found in memory share")
		}
		return nil, stacktrace.Propagate(err, "failed to get file from memory share")
	}
	return file, nil
}

// FileExistsInShare checks if a file is part of a memory share
func (r *MemoryShareRepository) FileExistsInShare(ctx context.Context, shareID int64, fileID int64) (bool, int64, error) {
	var ownerID int64
	err := r.DB.QueryRowContext(ctx, `
		SELECT file_owner_id FROM memory_share_files
		WHERE memory_share_id = $1 AND file_id = $2`, shareID, fileID).Scan(&ownerID)
	if err != nil {
		if err == sql.ErrNoRows {
			return false, 0, nil
		}
		return false, 0, stacktrace.Propagate(err, "failed to check file existence")
	}
	return true, ownerID, nil
}

// GetFilesWithKeys retrieves files along with their re-encrypted keys for public access
func (r *MemoryShareRepository) GetFilesWithKeys(ctx context.Context, shareID int64, fileIDs []int64) ([]ente.MemoryShareFile, error) {
	rows, err := r.DB.QueryContext(ctx, `
		SELECT id, memory_share_id, file_id, file_owner_id, file_enc_key, file_key_decryption_nonce, created_at
		FROM memory_share_files WHERE memory_share_id = $1 AND file_id = ANY($2)`, shareID, pq.Array(fileIDs))
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to get memory share files with keys")
	}
	defer rows.Close()

	var files []ente.MemoryShareFile
	for rows.Next() {
		var file ente.MemoryShareFile
		if err = rows.Scan(&file.ID, &file.MemoryShareID, &file.FileID, &file.FileOwnerID,
			&file.EncryptedKey, &file.KeyDecryptionNonce, &file.CreatedAt); err != nil {
			return nil, stacktrace.Propagate(err, "failed to scan memory share file")
		}
		files = append(files, file)
	}
	return files, nil
}
