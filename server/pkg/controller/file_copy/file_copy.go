package file_copy

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/s3config"
	"github.com/gin-gonic/gin"
)

type FileCopyController struct {
	S3Config       *s3config.S3Config
	FileController *controller.FileController
	CollectionCtrl *controller.CollectionController
}

func (fc *FileCopyController) CopyFiles(c *gin.Context, req ente.CopyFileSyncRequest) (interface{}, error) {
	userID := auth.GetUserID(c.Request.Header)
	err := fc.CollectionCtrl.IsCopyAllowed(c, userID, req)
	if err != nil {
		return nil, err
	}
	return nil, ente.NewInternalError("yet to implement actual copy")

}
