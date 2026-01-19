package llmchat

import (
	"fmt"
	"io"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/ente-io/museum/ente"
	llmchatRepo "github.com/ente-io/museum/pkg/repo/llmchat"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/s3config"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

const llmChatAttachmentPrefix = "llmchat/attachments"

type AttachmentController struct {
	S3Config            *s3config.S3Config
	Repo                *llmchatRepo.Repository
	SubscriptionChecker SubscriptionChecker
}

func (c *AttachmentController) maxAttachmentSize(userID int64) int64 {
	if c.SubscriptionChecker != nil && c.SubscriptionChecker.HasActiveSelfOrFamilySubscription(userID, false) == nil {
		return llmChatMaxAttachmentPaid
	}
	return llmChatMaxAttachmentFree
}

func (c *AttachmentController) Upload(ctx *gin.Context, attachmentID string) error {
	if attachmentID == "" {
		return stacktrace.Propagate(ente.ErrBadRequest, "missing attachment id")
	}
	if c.S3Config == nil {
		return stacktrace.Propagate(ente.ErrNotImplemented, "attachments not configured")
	}
	if ctx.Request.ContentLength <= 0 {
		return stacktrace.Propagate(ente.ErrBadRequest, "missing attachment size")
	}

	userID := auth.GetUserID(ctx.Request.Header)
	maxSize := c.maxAttachmentSize(userID)
	if ctx.Request.ContentLength > maxSize {
		return stacktrace.Propagate(&ente.ErrLlmChatAttachmentLimitReached, "")
	}

	objectKey := buildAttachmentObjectKey(userID, attachmentID)
	bucket := c.S3Config.GetHotBucket()
	s3Client := c.S3Config.GetHotS3Client()

	// Skip upload if attachment already exists with same size.
	headOutput, err := s3Client.HeadObjectWithContext(ctx.Request.Context(), &s3.HeadObjectInput{
		Bucket: bucket,
		Key:    aws.String(objectKey),
	})
	if err == nil && headOutput.ContentLength != nil && *headOutput.ContentLength == ctx.Request.ContentLength {
		_, _ = io.Copy(io.Discard, ctx.Request.Body)
		return nil
	}

	uploader := s3manager.NewUploaderWithClient(s3Client)
	_, err = uploader.UploadWithContext(ctx.Request.Context(), &s3manager.UploadInput{
		Bucket:      bucket,
		Key:         aws.String(objectKey),
		Body:        ctx.Request.Body,
		ContentType: aws.String("application/octet-stream"),
	})
	if err != nil {
		return stacktrace.Propagate(err, "failed to upload attachment")
	}

	return nil
}

func (c *AttachmentController) Download(ctx *gin.Context, attachmentID string) (io.ReadCloser, int64, error) {
	if attachmentID == "" {
		return nil, 0, stacktrace.Propagate(ente.ErrBadRequest, "missing attachment id")
	}
	if c.S3Config == nil {
		return nil, 0, stacktrace.Propagate(ente.ErrNotImplemented, "attachments not configured")
	}

	userID := auth.GetUserID(ctx.Request.Header)
	if c.Repo != nil {
		referenced, err := c.Repo.HasActiveAttachmentReference(ctx, userID, attachmentID)
		if err != nil {
			return nil, 0, stacktrace.Propagate(err, "failed to verify attachment access")
		}
		if !referenced {
			return nil, 0, stacktrace.Propagate(ente.ErrNotFound, "attachment not found")
		}
	}

	objectKey := buildAttachmentObjectKey(userID, attachmentID)
	bucket := c.S3Config.GetHotBucket()
	s3Client := c.S3Config.GetHotS3Client()

	output, err := s3Client.GetObjectWithContext(ctx.Request.Context(), &s3.GetObjectInput{
		Bucket: bucket,
		Key:    aws.String(objectKey),
	})
	if err != nil {
		if isAttachmentNotFound(err) {
			return nil, 0, stacktrace.Propagate(ente.ErrNotFound, "attachment not found")
		}
		return nil, 0, stacktrace.Propagate(err, "failed to download attachment")
	}

	contentLength := int64(0)
	if output.ContentLength != nil {
		contentLength = *output.ContentLength
	}

	return output.Body, contentLength, nil
}

func (c *AttachmentController) Delete(ctx *gin.Context, userID int64, attachmentID string) error {
	if attachmentID == "" {
		return stacktrace.Propagate(ente.ErrBadRequest, "missing attachment id")
	}
	if c.S3Config == nil {
		return stacktrace.Propagate(ente.ErrNotImplemented, "attachments not configured")
	}

	objectKey := buildAttachmentObjectKey(userID, attachmentID)
	bucket := c.S3Config.GetHotBucket()
	s3Client := c.S3Config.GetHotS3Client()

	_, err := s3Client.DeleteObjectWithContext(ctx.Request.Context(), &s3.DeleteObjectInput{
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
