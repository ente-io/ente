package controller

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/network"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
	"strconv"
	"strings"
)

const (
	_model = "hls_video"
)

// GetUploadURLs returns a bunch of presigned URLs for uploading files
func (c *FileController) GetVideoUploadUrl(ctx context.Context, userID int64, fileID int64, app ente.App) (*ente.UploadURL, error) {
	err := c.UsageCtrl.CanUploadFile(ctx, userID, nil, app)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	s3Client := c.S3Config.GetDerivedStorageS3Client()
	dc := c.S3Config.GetDerivedStorageDataCenter()
	bucket := c.S3Config.GetDerivedStorageBucket()
	objectKey := strconv.FormatInt(userID, 10) + "/ml-data/" + strconv.FormatInt(fileID, 10) + "/" + _model
	url, err := c.getObjectURL(s3Client, dc, bucket, objectKey)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	log.Infof("Got upload URL for %s", objectKey)
	return &url, nil
}

func (c *FileController) GetPreviewUrl(ctx context.Context, userID int64, fileID int64) (string, error) {
	err := c.verifyFileAccess(userID, fileID)
	if err != nil {
		return "", err
	}
	objectKey := strconv.FormatInt(userID, 10) + "/ml-data/" + strconv.FormatInt(fileID, 10) + "/hls_video"
	s3Client := c.S3Config.GetDerivedStorageS3Client()
	r, _ := s3Client.GetObjectRequest(&s3.GetObjectInput{
		Bucket: c.S3Config.GetDerivedStorageBucket(),
		Key:    &objectKey,
	})
	return r.Presign(PreSignedRequestValidityDuration)
}

func (c *FileController) GetPlaylist(ctx *gin.Context, fileID int64) (ente.EmbeddingObject, error) {
	objectKey := strconv.FormatInt(auth.GetUserID(ctx.Request.Header), 10) + "/ml-data/" + strconv.FormatInt(fileID, 10) + "/hls_video_playlist.m3u8"
	// check if object exists
	err := c.checkObjectExists(ctx, objectKey, c.S3Config.GetDerivedStorageDataCenter())
	if err != nil {
		return ente.EmbeddingObject{}, stacktrace.Propagate(ente.NewBadRequestWithMessage("Video playlist does not exist"), fmt.Sprintf("objectKey: %s", objectKey))
	}
	return c.downloadObject(ctx, objectKey, c.S3Config.GetDerivedStorageDataCenter())
}

func (c *FileController) ReportVideoPreview(ctx *gin.Context, req ente.InsertOrUpdateEmbeddingRequest) error {
	userID := auth.GetUserID(ctx.Request.Header)
	if strings.Compare(req.Model, "hls_video") != 0 {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage("Model should be hls_video"), "Invalid fileID")
	}
	count, err := c.CollectionRepo.GetCollectionCount(req.FileID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if count < 1 {
		return stacktrace.Propagate(ente.ErrNotFound, "")
	}
	version := 1
	if req.Version != nil {
		version = *req.Version
	}
	objectKey := strconv.FormatInt(userID, 10) + "/ml-data/" + strconv.FormatInt(req.FileID, 10) + "/hls_video"
	playlistKey := objectKey + "_playlist.m3u8"

	// verify that objectKey exists
	err = c.checkObjectExists(ctx, objectKey, c.S3Config.GetDerivedStorageDataCenter())
	if err != nil {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage("Video object does not exist, upload that before playlist reporting"), fmt.Sprintf("objectKey: %s", objectKey))
	}

	obj := ente.EmbeddingObject{
		Version:            version,
		EncryptedEmbedding: req.EncryptedEmbedding,
		DecryptionHeader:   req.DecryptionHeader,
		Client:             network.GetClientInfo(ctx),
	}
	_, uploadErr := c.uploadObject(obj, playlistKey, c.S3Config.GetDerivedStorageDataCenter())
	if uploadErr != nil {
		log.Error(uploadErr)
		return stacktrace.Propagate(uploadErr, "")
	}
	return nil
}

func (c *FileController) uploadObject(obj ente.EmbeddingObject, key string, dc string) (int, error) {
	embeddingObj, _ := json.Marshal(obj)
	s3Client := c.S3Config.GetS3Client(dc)
	s3Bucket := c.S3Config.GetBucket(dc)
	uploader := s3manager.NewUploaderWithClient(&s3Client)
	up := s3manager.UploadInput{
		Bucket: s3Bucket,
		Key:    &key,
		Body:   bytes.NewReader(embeddingObj),
	}
	result, err := uploader.Upload(&up)
	if err != nil {
		log.Error(err)
		return -1, stacktrace.Propagate(err, "")
	}

	log.Infof("Uploaded to bucket %s", result.Location)
	return len(embeddingObj), nil
}

func (c *FileController) downloadObject(ctx context.Context, objectKey string, dc string) (ente.EmbeddingObject, error) {
	var obj ente.EmbeddingObject
	buff := &aws.WriteAtBuffer{}
	bucket := c.S3Config.GetBucket(dc)
	s3Client := c.S3Config.GetS3Client(dc)
	downloader := s3manager.NewDownloaderWithClient(&s3Client)
	_, err := downloader.DownloadWithContext(ctx, buff, &s3.GetObjectInput{
		Bucket: bucket,
		Key:    &objectKey,
	})
	if err != nil {
		return obj, err
	}
	err = json.Unmarshal(buff.Bytes(), &obj)
	if err != nil {
		return obj, stacktrace.Propagate(err, "unmarshal failed")
	}
	return obj, nil
}

func (c *FileController) checkObjectExists(ctx context.Context, objectKey string, dc string) error {
	s3Client := c.S3Config.GetS3Client(dc)
	_, err := s3Client.HeadObject(&s3.HeadObjectInput{
		Bucket: c.S3Config.GetBucket(dc),
		Key:    &objectKey,
	})
	if err != nil {
		return err
	}
	return nil
}
