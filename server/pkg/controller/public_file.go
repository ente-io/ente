package controller

import (
	"github.com/ente-io/museum/ente"
	emailCtrl "github.com/ente-io/museum/pkg/controller/email"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/repo/public"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"github.com/lithammer/shortuuid/v3"
)

// PublicFileController controls share collection operations
type PublicFileController struct {
	FileController        *FileController
	EmailNotificationCtrl *emailCtrl.EmailNotificationController
	PublicCollectionRepo  *public.PublicCollectionRepository
	PublicFileRepo        *public.PublicFileRepository
	CollectionRepo        *repo.CollectionRepository
	UserRepo              *repo.UserRepository
	JwtSecret             []byte
}

func (c *PublicFileController) CreateFileUrl(ctx *gin.Context, req ente.CreateFileUrl) (*ente.FileUrl, error) {
	actorUserID := auth.GetUserID(ctx.Request.Header)
	accessToken := shortuuid.New()[0:AccessTokenLength]
	err := c.PublicFileRepo.Insert(ctx, req.FileID, actorUserID, accessToken)
	if err == nil {
		return &ente.FileUrl{
			LinkID: accessToken,
			FileID: req.FileID,
		}, nil
	}
	return nil, stacktrace.NewError("This endpoint is deprecated. Please use CreatePublicCollectionToken instead")
}
