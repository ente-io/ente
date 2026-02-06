package memory_share

import (
	"context"
	"strings"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/access"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"github.com/lithammer/shortuuid/v3"
)

const (
	AccessTokenLength = 10
)

// Controller handles memory share operations
type Controller struct {
	Repo       *repo.MemoryShareRepository
	FileRepo   *repo.FileRepository
	AccessCtrl access.Controller
}

// NewController creates a new memory share controller
func NewController(
	repo *repo.MemoryShareRepository,
	fileRepo *repo.FileRepository,
	accessCtrl access.Controller,
) *Controller {
	return &Controller{
		Repo:       repo,
		FileRepo:   fileRepo,
		AccessCtrl: accessCtrl,
	}
}

// Create creates a new memory share
func (c *Controller) Create(ctx *gin.Context, userID int64, req ente.CreateMemoryShareRequest) (*ente.CreateMemoryShareResponse, error) {
	fileIDs := make([]int64, len(req.Files))
	for i, f := range req.Files {
		fileIDs[i] = f.FileID
	}

	err := c.AccessCtrl.CanAccessFile(ctx, &access.CanAccessFileParams{
		ActorUserID: userID,
		FileIDs:     fileIDs,
	})
	if err != nil {
		return nil, stacktrace.Propagate(ente.ErrPermissionDenied, "user cannot access all files")
	}

	ownerMap, err := c.FileRepo.GetOwnerToFileIDsMap(ctx, fileIDs)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to get file ownership map")
	}

	fileOwnerMap := make(map[int64]int64)
	for ownerID, fIDs := range ownerMap {
		for _, fid := range fIDs {
			fileOwnerMap[fid] = ownerID
		}
	}

	accessToken := strings.ToUpper(shortuuid.New()[0:AccessTokenLength])

	share := ente.MemoryShare{
		UserID:             userID,
		Type:               ente.MemoryShareTypeShare,
		MetadataCipher:     req.MetadataCipher,
		MetadataNonce:      req.MetadataNonce,
		EncryptedKey:       req.EncryptedKey,
		KeyDecryptionNonce: req.KeyDecryptionNonce,
		AccessToken:        accessToken,
	}

	share, err = c.Repo.Create(ctx, share)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to create memory share")
	}

	shareFiles := make([]ente.MemoryShareFile, len(req.Files))
	now := time.Microseconds()
	for i, f := range req.Files {
		shareFiles[i] = ente.MemoryShareFile{
			MemoryShareID:      share.ID,
			FileID:             f.FileID,
			FileOwnerID:        fileOwnerMap[f.FileID],
			EncryptedKey:       f.EncryptedKey,
			KeyDecryptionNonce: f.KeyDecryptionNonce,
			CreatedAt:          now,
		}
	}

	err = c.Repo.AddFiles(ctx, share.ID, shareFiles)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to add files to memory share")
	}

	return &ente.CreateMemoryShareResponse{MemoryShare: share}, nil
}

// List returns all memory shares for a user
func (c *Controller) List(ctx context.Context, userID int64) (*ente.ListMemorySharesResponse, error) {
	shares, err := c.Repo.GetByUserID(ctx, userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to list memory shares")
	}
	if shares == nil {
		shares = []ente.MemoryShare{}
	}
	return &ente.ListMemorySharesResponse{MemoryShares: shares}, nil
}

// Delete soft-deletes a memory share
func (c *Controller) Delete(ctx context.Context, userID int64, shareID int64) error {
	err := c.Repo.Delete(ctx, shareID, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to delete memory share")
	}
	return nil
}

// GetByID retrieves a memory share by ID (for owner only)
func (c *Controller) GetByID(ctx context.Context, userID int64, shareID int64) (*ente.MemoryShare, error) {
	share, err := c.Repo.GetByID(ctx, shareID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to get memory share")
	}
	if share.UserID != userID {
		return nil, stacktrace.Propagate(ente.ErrPermissionDenied, "user does not own this memory share")
	}
	return share, nil
}
