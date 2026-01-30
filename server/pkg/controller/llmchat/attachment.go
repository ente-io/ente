package llmchat

import (
	"context"
	"database/sql"
	"fmt"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/ente-io/museum/ente"
	model "github.com/ente-io/museum/ente/llmchat"
	llmchatRepo "github.com/ente-io/museum/pkg/repo/llmchat"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/s3config"
	timeUtil "github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

const (
	llmChatAttachmentPrefix                 = "llmchat/attachments"
	llmChatPresignedRequestValidityDuration = 7 * 24 * time.Hour
)

type AttachmentController struct {
	S3Config            *s3config.S3Config
	Repo                *llmchatRepo.Repository
	SubscriptionChecker SubscriptionChecker
}

func (c *AttachmentController) maxAttachmentSize(userID int64) int64 {
	return maxAttachmentSizeForUser(c.SubscriptionChecker, userID)
}

func (c *AttachmentController) maxAttachmentStorage(userID int64) int64 {
	return maxAttachmentStorageForUser(c.SubscriptionChecker, userID)
}

func (c *AttachmentController) GetUploadURL(
	ctx *gin.Context,
	attachmentID string,
	req model.GetAttachmentUploadURLRequest,
	force bool,
) (model.AttachmentUploadURLResponse, error) {
	if attachmentID == "" {
		return model.AttachmentUploadURLResponse{}, stacktrace.Propagate(ente.ErrBadRequest, "missing attachment id")
	}
	if c.S3Config == nil {
		return model.AttachmentUploadURLResponse{}, stacktrace.Propagate(ente.ErrNotImplemented, "attachments not configured")
	}
	if c.Repo == nil {
		return model.AttachmentUploadURLResponse{}, stacktrace.Propagate(ente.ErrNotImplemented, "attachments repo not configured")
	}
	if req.ContentLength <= 0 {
		return model.AttachmentUploadURLResponse{}, stacktrace.Propagate(ente.ErrBadRequest, "content_length must be > 0")
	}

	userID := auth.GetUserID(ctx.Request.Header)
	maxSize := c.maxAttachmentSize(userID)
	if req.ContentLength > maxSize {
		return model.AttachmentUploadURLResponse{}, stacktrace.Propagate(&ente.ErrLlmChatAttachmentLimitReached, "")
	}
	referenced, err := c.Repo.HasActiveAttachmentReference(ctx, userID, attachmentID)
	if err != nil {
		return model.AttachmentUploadURLResponse{}, stacktrace.Propagate(err, "failed to check attachment reference")
	}
	if referenced && !force {
		exists, err := c.attachmentExists(ctx, userID, attachmentID)
		if err != nil {
			return model.AttachmentUploadURLResponse{}, err
		}
		if !exists {
			if err := c.Repo.DeleteAttachmentRecords(ctx, userID, attachmentID); err != nil {
				return model.AttachmentUploadURLResponse{}, stacktrace.Propagate(err, "failed to clear attachment records")
			}
			referenced = false
		}
	}
	if referenced && !force {
		return model.AttachmentUploadURLResponse{}, stacktrace.Propagate(ente.NewConflictError("attachment is already committed"), "")
	}

	maxStorage := c.maxAttachmentStorage(userID)
	if maxStorage > 0 {
		usage, err := c.Repo.GetActiveAttachmentUsage(ctx, userID)
		if err != nil {
			return model.AttachmentUploadURLResponse{}, stacktrace.Propagate(err, "failed to fetch llmchat attachment usage")
		}
		if usage+req.ContentLength > maxStorage {
			return model.AttachmentUploadURLResponse{}, stacktrace.Propagate(&ente.ErrLlmChatAttachmentLimitReached, "")
		}
	}

	objectKey := buildAttachmentObjectKey(userID, attachmentID)
	s3Client := c.S3Config.GetHotS3Client()
	dc := c.S3Config.GetHotDataCenter()
	bucket := c.S3Config.GetHotBucket()

	putInput := &s3.PutObjectInput{
		Bucket: bucket,
		Key:    aws.String(objectKey),
	}
	putReq, _ := s3Client.PutObjectRequest(putInput)
	url, err := putReq.Presign(llmChatPresignedRequestValidityDuration)
	if err != nil {
		return model.AttachmentUploadURLResponse{}, stacktrace.Propagate(err, "failed to presign attachment upload url")
	}

	expiry := timeUtil.Microseconds() + (2 * llmChatPresignedRequestValidityDuration.Microseconds())
	_, err = c.Repo.DB.ExecContext(
		ctx,
		`INSERT INTO temp_objects(object_key, expiration_time, bucket_id, is_multipart, upload_id)
		VALUES($1, $2, $3, FALSE, NULL)
		ON CONFLICT (object_key) DO UPDATE
			SET expiration_time = EXCLUDED.expiration_time,
				bucket_id = EXCLUDED.bucket_id,
				is_multipart = FALSE,
				upload_id = NULL`,
		objectKey,
		expiry,
		dc,
	)
	if err != nil {
		return model.AttachmentUploadURLResponse{}, stacktrace.Propagate(err, "failed to persist llmchat temp object")
	}

	return model.AttachmentUploadURLResponse{
		ObjectKey: objectKey,
		URL:       url,
	}, nil
}

func (c *AttachmentController) attachmentExists(
	ctx *gin.Context,
	userID int64,
	attachmentID string,
) (bool, error) {
	objectKey := buildAttachmentObjectKey(userID, attachmentID)
	bucket := c.S3Config.GetHotBucket()
	s3Client := c.S3Config.GetHotS3Client()

	_, err := s3Client.HeadObjectWithContext(ctx, &s3.HeadObjectInput{
		Bucket: bucket,
		Key:    aws.String(objectKey),
	})
	if err != nil {
		if isAttachmentNotFound(err) {
			return false, nil
		}
		return false, stacktrace.Propagate(err, "failed to check attachment in storage")
	}
	return true, nil
}

func (c *AttachmentController) VerifyUploaded(
	ctx *gin.Context,
	userID int64,
	attachmentID string,
	expectedSize int64,
) error {
	if attachmentID == "" {
		return stacktrace.Propagate(ente.ErrBadRequest, "missing attachment id")
	}
	if c.S3Config == nil {
		return stacktrace.Propagate(ente.ErrNotImplemented, "attachments not configured")
	}

	objectKey := buildAttachmentObjectKey(userID, attachmentID)
	bucket := c.S3Config.GetHotBucket()
	s3Client := c.S3Config.GetHotS3Client()

	out, err := s3Client.HeadObjectWithContext(ctx, &s3.HeadObjectInput{
		Bucket: bucket,
		Key:    aws.String(objectKey),
	})
	if err != nil {
		if isAttachmentNotFound(err) {
			return stacktrace.Propagate(ente.ErrBadRequest, "attachment not uploaded")
		}
		return stacktrace.Propagate(err, "failed to verify attachment")
	}
	if out.ContentLength != nil && expectedSize > 0 && *out.ContentLength != expectedSize {
		return stacktrace.Propagate(ente.ErrBadRequest, "attachment size mismatch")
	}
	return nil
}

func (c *AttachmentController) GetDownloadURL(ctx *gin.Context, attachmentID string) (string, error) {
	if attachmentID == "" {
		return "", stacktrace.Propagate(ente.ErrBadRequest, "missing attachment id")
	}
	if c.S3Config == nil {
		return "", stacktrace.Propagate(ente.ErrNotImplemented, "attachments not configured")
	}
	if c.Repo == nil {
		return "", stacktrace.Propagate(ente.ErrNotImplemented, "attachments repo not configured")
	}

	userID := auth.GetUserID(ctx.Request.Header)
	referenced, err := c.Repo.HasActiveAttachmentReference(ctx, userID, attachmentID)
	if err != nil {
		return "", stacktrace.Propagate(err, "failed to verify attachment access")
	}
	if !referenced {
		return "", stacktrace.Propagate(ente.ErrNotFound, "attachment not found")
	}

	exists, err := c.attachmentExists(ctx, userID, attachmentID)
	if err != nil {
		return "", err
	}
	if !exists {
		if err := c.Repo.DeleteAttachmentRecords(ctx, userID, attachmentID); err != nil {
			return "", stacktrace.Propagate(err, "failed to clear attachment records")
		}
		return "", stacktrace.Propagate(ente.ErrNotFound, "attachment not found")
	}

	objectKey := buildAttachmentObjectKey(userID, attachmentID)
	s3Client := c.S3Config.GetHotS3Client()
	bucket := c.S3Config.GetHotBucket()

	getReq, _ := s3Client.GetObjectRequest(&s3.GetObjectInput{
		Bucket: bucket,
		Key:    aws.String(objectKey),
	})
	url, err := getReq.Presign(llmChatPresignedRequestValidityDuration)
	if err != nil {
		return "", stacktrace.Propagate(err, "failed to presign attachment download url")
	}
	return url, nil
}

func (c *AttachmentController) Delete(ctx context.Context, userID int64, attachmentID string) error {
	if attachmentID == "" {
		return stacktrace.Propagate(ente.ErrBadRequest, "missing attachment id")
	}
	if c.S3Config == nil {
		return stacktrace.Propagate(ente.ErrNotImplemented, "attachments not configured")
	}

	objectKey := buildAttachmentObjectKey(userID, attachmentID)
	bucket := c.S3Config.GetHotBucket()
	s3Client := c.S3Config.GetHotS3Client()

	_, err := s3Client.DeleteObjectWithContext(ctx, &s3.DeleteObjectInput{
		Bucket: bucket,
		Key:    aws.String(objectKey),
	})
	if err != nil {
		if isAttachmentNotFound(err) {
			return nil
		}
		return stacktrace.Propagate(err, "failed to delete attachment")
	}
	return nil
}

func (c *AttachmentController) CleanupExpiredTempUploads(ctx context.Context, limit int) (int, error) {
	if c.S3Config == nil || c.Repo == nil {
		return 0, nil
	}
	if limit <= 0 {
		limit = 1000
	}

	now := timeUtil.Microseconds()

	tx, err := c.Repo.DB.BeginTx(ctx, nil)
	if err != nil {
		return 0, stacktrace.Propagate(err, "failed to begin transaction")
	}
	defer func() {
		_ = tx.Rollback()
	}()

	rows, err := tx.QueryContext(ctx, `SELECT object_key, bucket_id
		FROM temp_objects
		WHERE expiration_time <= $1 AND object_key LIKE 'llmchat/attachments/%'
		LIMIT $2
		FOR UPDATE SKIP LOCKED`,
		now,
		limit,
	)
	if err != nil {
		return 0, stacktrace.Propagate(err, "failed to query expired llmchat temp objects")
	}
	defer rows.Close()

	type tempObj struct {
		ObjectKey string
		BucketID  sql.NullString
	}

	objs := make([]tempObj, 0)
	for rows.Next() {
		var o tempObj
		if err := rows.Scan(&o.ObjectKey, &o.BucketID); err != nil {
			return 0, stacktrace.Propagate(err, "failed to scan expired llmchat temp objects")
		}
		objs = append(objs, o)
	}
	if err := rows.Err(); err != nil {
		return 0, stacktrace.Propagate(err, "failed to iterate expired llmchat temp objects")
	}

	deleted := 0
	for _, o := range objs {
		dc := c.S3Config.GetHotDataCenter()
		if o.BucketID.Valid && o.BucketID.String != "" {
			dc = o.BucketID.String
		}
		bucket := c.S3Config.GetBucket(dc)
		client := c.S3Config.GetS3Client(dc)

		_, err := client.DeleteObjectWithContext(ctx, &s3.DeleteObjectInput{
			Bucket: bucket,
			Key:    aws.String(o.ObjectKey),
		})
		if err != nil && !isAttachmentNotFound(err) {
			newExpiry := timeUtil.MicrosecondsAfterDays(1)
			_, _ = tx.ExecContext(ctx, `UPDATE temp_objects SET expiration_time = $1 WHERE object_key = $2`, newExpiry, o.ObjectKey)
			continue
		}

		if _, err := tx.ExecContext(ctx, `DELETE FROM temp_objects WHERE object_key = $1`, o.ObjectKey); err != nil {
			return 0, stacktrace.Propagate(err, "failed to delete llmchat temp object")
		}
		deleted++
	}

	if err := tx.Commit(); err != nil {
		return 0, stacktrace.Propagate(err, "failed to commit transaction")
	}
	return deleted, nil
}

func (c *AttachmentController) CleanupDeletedAttachments(ctx context.Context, limit int) (int, error) {
	if c.S3Config == nil || c.Repo == nil {
		return 0, nil
	}
	refs, err := c.Repo.GetDeletedAttachmentCandidates(ctx, limit)
	if err != nil {
		return 0, stacktrace.Propagate(err, "failed to fetch deleted llmchat attachments")
	}

	deleted := 0
	for _, ref := range refs {
		referenced, err := c.Repo.HasActiveAttachmentReference(ctx, ref.UserID, ref.AttachmentID)
		if err != nil {
			return deleted, stacktrace.Propagate(err, "failed to check llmchat attachment reference")
		}
		if referenced {
			continue
		}
		if err := c.Delete(ctx, ref.UserID, ref.AttachmentID); err != nil {
			continue
		}
		if err := c.Repo.DeleteAttachmentRecords(ctx, ref.UserID, ref.AttachmentID); err != nil {
			return deleted, stacktrace.Propagate(err, "failed to delete llmchat attachment records")
		}
		deleted++
	}
	return deleted, nil
}

func buildAttachmentObjectKey(userID int64, attachmentID string) string {
	return fmt.Sprintf("%s/%d/%s", llmChatAttachmentPrefix, userID, attachmentID)
}

func isAttachmentNotFound(err error) bool {
	if awsErr, ok := err.(awserr.Error); ok {
		switch awsErr.Code() {
		case s3.ErrCodeNoSuchKey, "NotFound":
			return true
		}
	}
	return false
}
