package public

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/repo/public"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"github.com/lithammer/shortuuid/v3"
)

// FileLinkController controls share collection operations
type FileLinkController struct {
	FileController *controller.FileController
	FileLinkRepo   *public.FileLinkRepository
	FileRepo       *repo.FileRepository
	JwtSecret      []byte
}

func (c *FileLinkController) CreateLink(ctx *gin.Context, req ente.CreateFileUrl) (*ente.FileUrl, error) {
	actorUserID := auth.GetUserID(ctx.Request.Header)
	app := auth.GetApp(ctx)
	if req.App != app {
		return nil, stacktrace.Propagate(ente.NewBadRequestWithMessage("app mismatch"), "app mismatch")
	}
	file, err := c.FileRepo.GetFileAttributes(req.FileID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to get file attributes")
	}
	if actorUserID != file.OwnerID {
		return nil, stacktrace.Propagate(ente.NewPermissionDeniedError("not file owner"), "")
	}
	accessToken := shortuuid.New()[0:AccessTokenLength]
	_, err = c.FileLinkRepo.Insert(ctx, req.FileID, actorUserID, accessToken, app)
	if err == nil || err == ente.ErrActiveLinkAlreadyExists {
		row, rowErr := c.FileLinkRepo.GetFileUrlRowByFileID(ctx, req.FileID)
		if rowErr != nil {
			return nil, stacktrace.Propagate(rowErr, "failed to get active file url token")
		}
		return c.mapRowToFileUrl(ctx, row), nil
	}
	return nil, stacktrace.Propagate(err, "failed to create public file link")
}

// Disable all public accessTokens generated for the given fileID till date.
func (c *FileLinkController) Disable(ctx *gin.Context, fileID int64) error {
	userID := auth.GetUserID(ctx.Request.Header)
	file, err := c.FileRepo.GetFileAttributes(fileID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to get file attributes")
	}
	if userID != file.OwnerID {
		return stacktrace.Propagate(ente.NewPermissionDeniedError("not file owner"), "")
	}
	return c.FileLinkRepo.DisableLinkForFiles(ctx, []int64{fileID})
}

func (c *FileLinkController) GetUrls(ctx *gin.Context, sinceTime int64, limit int64) ([]*ente.FileUrl, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	app := auth.GetApp(ctx)
	fileLinks, err := c.FileLinkRepo.GetFileUrls(ctx, userID, sinceTime, limit, app)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to get file urls")
	}
	var fileUrls []*ente.FileUrl
	for _, row := range fileLinks {
		fileUrls = append(fileUrls, c.mapRowToFileUrl(ctx, row))
	}
	return fileUrls, nil
}

func (c *FileLinkController) UpdateSharedUrl(ctx *gin.Context, req ente.UpdateFileUrl) (*ente.FileUrl, error) {
	if err := req.Validate(); err != nil {
		return nil, stacktrace.Propagate(err, "invalid request")
	}
	fileLinkRow, err := c.FileLinkRepo.GetActiveFileUrlToken(ctx, req.FileID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to get file link info")
	}
	if fileLinkRow.OwnerID != auth.GetUserID(ctx.Request.Header) {
		return nil, stacktrace.Propagate(ente.NewPermissionDeniedError("not file owner"), "")
	}
	if req.ValidTill != nil {
		fileLinkRow.ValidTill = *req.ValidTill
	}
	if req.DeviceLimit != nil {
		fileLinkRow.DeviceLimit = *req.DeviceLimit
	}
	if req.PassHash != nil && req.Nonce != nil && req.OpsLimit != nil && req.MemLimit != nil {
		fileLinkRow.PassHash = req.PassHash
		fileLinkRow.Nonce = req.Nonce
		fileLinkRow.OpsLimit = req.OpsLimit
		fileLinkRow.MemLimit = req.MemLimit
	} else if req.DisablePassword != nil && *req.DisablePassword {
		fileLinkRow.PassHash = nil
		fileLinkRow.Nonce = nil
		fileLinkRow.OpsLimit = nil
		fileLinkRow.MemLimit = nil
	}
	if req.EnableDownload != nil {
		fileLinkRow.EnableDownload = *req.EnableDownload
	}

	err = c.FileLinkRepo.UpdateLink(ctx, *fileLinkRow)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return c.mapRowToFileUrl(ctx, fileLinkRow), nil
}

func (c *FileLinkController) Info(ctx *gin.Context) (*ente.File, error) {
	accessContext := auth.MustGetFileLinkAccessContext(ctx)
	return c.FileRepo.GetFileAttributes(accessContext.FileID)
}

func (c *FileLinkController) PassInfo(ctx *gin.Context) (*ente.FileLinkRow, error) {
	accessContext := auth.MustGetFileLinkAccessContext(ctx)
	return c.FileLinkRepo.GetFileUrlRowByFileID(ctx, accessContext.FileID)
}

// VerifyPassword verifies if the user has provided correct pw hash. If yes, it returns a signed jwt token which can be
// used by the client to pass in other requests for public collection.
// Having a separate endpoint for password validation allows us to easily rate-limit the attempts for brute-force
// attack for guessing password.
func (c *FileLinkController) VerifyPassword(ctx *gin.Context, req ente.VerifyPasswordRequest) (*ente.VerifyPasswordResponse, error) {
	accessContext := auth.MustGetFileLinkAccessContext(ctx)
	collectionLinkRow, err := c.FileLinkRepo.GetActiveFileUrlToken(ctx, accessContext.FileID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to get public collection info")
	}
	return verifyPassword(c.JwtSecret, collectionLinkRow.PassHash, req)
}

func (c *FileLinkController) ValidateJWTToken(ctx *gin.Context, jwtToken string, passwordHash string) error {
	return validateJWTToken(c.JwtSecret, jwtToken, passwordHash)
}

func (c *FileLinkController) mapRowToFileUrl(ctx *gin.Context, row *ente.FileLinkRow) *ente.FileUrl {
	app := auth.GetApp(ctx)
	var url string
	if app == ente.Locker {
		url = c.FileLinkRepo.LockerFileLink(row.Token)
	} else {
		url = c.FileLinkRepo.PhotoLink(row.Token)
	}
	return &ente.FileUrl{
		LinkID:          row.LinkID,
		FileID:          row.FileID,
		URL:             url,
		OwnerID:         row.OwnerID,
		ValidTill:       row.ValidTill,
		DeviceLimit:     row.DeviceLimit,
		PasswordEnabled: row.PassHash != nil,
		Nonce:           row.Nonce,
		OpsLimit:        row.OpsLimit,
		MemLimit:        row.MemLimit,
		EnableDownload:  row.EnableDownload,
		CreatedAt:       row.CreatedAt,
	}
}
