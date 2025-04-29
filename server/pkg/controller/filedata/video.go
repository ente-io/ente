package filedata

import (
	"context"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/ente/filedata"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/network"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

func (c *Controller) InsertVideoPreview(ctx *gin.Context, req *filedata.VidPreviewRequest) error {
	if err := req.Validate(); err != nil {
		return stacktrace.Propagate(err, "validation failed")
	}
	userID := auth.GetUserID(ctx.Request.Header)
	err := c._checkPreviewWritePerm(ctx, req.FileID, userID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	fileOwnerID := userID

	bucketID := c.S3Config.GetBucketID(ente.PreviewVideo)
	fileObjectKey := filedata.ObjectKey(req.FileID, fileOwnerID, ente.PreviewVideo, &req.ObjectID)
	objectKey := filedata.ObjectMetadataKey(req.FileID, fileOwnerID, ente.PreviewVideo, &req.ObjectID)

	if sizeErr := c.verifySize(bucketID, fileObjectKey, req.ObjectSize); sizeErr != nil {
		return stacktrace.Propagate(sizeErr, "failed to validate size")
	}
	// Start a goroutine to handle the upload and insert operations
	//go func() {
	obj := filedata.S3FileMetadata{
		Version:          *req.Version,
		EncryptedData:    req.Playlist,
		DecryptionHeader: req.PlayListHeader,
		Client:           network.GetClientInfo(ctx),
	}
	logger := log.
		WithField("objectKey", objectKey).
		WithField("fileID", req.FileID).
		WithField("type", ente.PreviewVideo)
	size, uploadErr := c.uploadObject(obj, objectKey, bucketID)
	if uploadErr != nil {
		logger.WithError(uploadErr).Error("upload failed")
		return nil
	}
	row := filedata.Row{
		FileID:       req.FileID,
		Type:         ente.PreviewVideo,
		UserID:       fileOwnerID,
		Size:         size + req.ObjectSize,
		LatestBucket: bucketID,
		ObjectID:     &req.ObjectID,
		ObjectNonce:  nil,
		ObjectSize:   &req.ObjectSize,
	}
	dbInsertErr := c.Repo.InsertOrUpdatePreviewData(context.Background(), row, fileObjectKey)
	if dbInsertErr != nil {
		logger.WithError(dbInsertErr).Error("insert or update failed")
		return nil
	}
	//}()
	return nil

}
