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
	CollectionRepo *repo.CollectionRepository
	UserRepo       *repo.UserRepository
	JwtSecret      []byte
}

func (c *FileLinkController) CreateLink(ctx *gin.Context, req ente.CreateFileUrl) (*ente.FileUrl, error) {
	actorUserID := auth.GetUserID(ctx.Request.Header)
	accessToken := shortuuid.New()[0:AccessTokenLength]
	_, err := c.FileLinkRepo.Insert(ctx, req.FileID, actorUserID, accessToken)
	if err == nil {
		row, rowErr := c.FileLinkRepo.GetActiveFileUrlToken(ctx, req.FileID)
		if rowErr != nil {
			return nil, stacktrace.Propagate(rowErr, "failed to get active file url token")
		}
		return c.mapRowToFileUrl(ctx, row), nil
	}
	return nil, stacktrace.Propagate(err, "failed to create public file link")
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
