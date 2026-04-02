package contact

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/ente-io/museum/ente"
	contactmodel "github.com/ente-io/museum/ente/contact"
	basecontroller "github.com/ente-io/museum/pkg/controller"
	contactrepo "github.com/ente-io/museum/pkg/repo/contact"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/s3config"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

type Controller struct {
	Repo                    *contactrepo.Repository
	ObjectCleanupController *basecontroller.ObjectCleanupController
	S3Config                *s3config.S3Config
}

func New(
	repo *contactrepo.Repository,
	objectCleanupController *basecontroller.ObjectCleanupController,
	s3Config *s3config.S3Config,
) *Controller {
	return &Controller{
		Repo:                    repo,
		ObjectCleanupController: objectCleanupController,
		S3Config:                s3Config,
	}
}

func (c *Controller) Create(ctx *gin.Context, req contactmodel.CreateRequest) (*contactmodel.Entity, error) {
	if err := req.Validate(); err != nil {
		return nil, stacktrace.Propagate(err, "invalid create contact request")
	}
	userID := auth.GetUserID(ctx.Request.Header)
	canCreate, err := c.Repo.CanCreateContact(ctx, userID, req.ContactUserID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to validate contact eligibility")
	}
	if !canCreate {
		return nil, stacktrace.Propagate(
			ente.NewBadRequestWithMessage("contactUserID is not eligible to be added as a contact"),
			"",
		)
	}
	id, err := c.Repo.Create(ctx, userID, req)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return c.Repo.Get(ctx, userID, id)
}

func (c *Controller) Get(ctx *gin.Context, contactID string) (*contactmodel.Entity, error) {
	if !contactmodel.IsValidContactID(contactID) {
		return nil, ente.NewBadRequestWithMessage("invalid contact id")
	}
	userID := auth.GetUserID(ctx.Request.Header)
	return c.Repo.Get(ctx, userID, contactID)
}

func (c *Controller) GetDiff(ctx *gin.Context, req contactmodel.DiffRequest) ([]contactmodel.Entity, error) {
	if req.Limit <= 0 || req.Limit > 5000 {
		return nil, ente.NewBadRequestWithMessage("limit must be between 1 and 5000")
	}
	userID := auth.GetUserID(ctx.Request.Header)
	return c.Repo.GetDiff(ctx, userID, *req.SinceTime, req.Limit)
}

func (c *Controller) Update(ctx *gin.Context, contactID string, req contactmodel.UpdateRequest) (*contactmodel.Entity, error) {
	if !contactmodel.IsValidContactID(contactID) {
		return nil, ente.NewBadRequestWithMessage("invalid contact id")
	}
	if err := req.Validate(); err != nil {
		return nil, stacktrace.Propagate(err, "invalid update contact request")
	}
	userID := auth.GetUserID(ctx.Request.Header)
	if err := c.Repo.Update(ctx, userID, contactID, req); err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return c.Repo.Get(ctx, userID, contactID)
}

func (c *Controller) Delete(ctx *gin.Context, contactID string) error {
	if !contactmodel.IsValidContactID(contactID) {
		return ente.NewBadRequestWithMessage("invalid contact id")
	}
	userID := auth.GetUserID(ctx.Request.Header)
	return c.Repo.Delete(ctx, userID, contactID)
}

func (c *Controller) GetProfilePictureUploadURL(ctx *gin.Context, contactID string, req contactmodel.ProfilePictureUploadURLRequest) (*contactmodel.ProfilePictureUploadURL, error) {
	if !contactmodel.IsValidContactID(contactID) {
		return nil, ente.NewBadRequestWithMessage("invalid contact id")
	}
	if err := req.Validate(); err != nil {
		return nil, stacktrace.Propagate(err, "invalid profile picture upload-url request")
	}

	userID := auth.GetUserID(ctx.Request.Header)
	entity, err := c.Repo.Get(ctx, userID, contactID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if entity.IsDeleted {
		return nil, stacktrace.Propagate(ente.NewBadRequestWithMessage("contact is already deleted"), "")
	}

	attachmentID := contactmodel.NewAttachmentID()
	objectKey := contactmodel.AttachmentObjectKey(userID, contactmodel.ProfilePicture, attachmentID)
	dc := c.S3Config.GetAttachmentBucketID(string(contactmodel.ProfilePicture))

	s3Client := c.S3Config.GetS3Client(dc)
	putReq, _ := s3Client.PutObjectRequest(&s3.PutObjectInput{
		Bucket:        c.S3Config.GetBucket(dc),
		Key:           aws.String(objectKey),
		ContentLength: aws.Int64(req.ContentLength),
		ContentMD5:    aws.String(req.ContentMD5),
	})
	url, err := putReq.Presign(basecontroller.PreSignedRequestValidityDuration)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to presign profile picture upload url")
	}
	if err := c.ObjectCleanupController.AddTempObjectKey(objectKey, dc); err != nil {
		return nil, stacktrace.Propagate(err, "failed to stage temp object for profile picture upload")
	}

	return &contactmodel.ProfilePictureUploadURL{
		AttachmentID: attachmentID,
		URL:          url,
	}, nil
}

func (c *Controller) AttachProfilePicture(ctx *gin.Context, contactID string, req contactmodel.CommitProfilePictureRequest) (*contactmodel.Entity, error) {
	if !contactmodel.IsValidContactID(contactID) {
		return nil, ente.NewBadRequestWithMessage("invalid contact id")
	}
	if err := req.Validate(); err != nil {
		return nil, stacktrace.Propagate(err, "invalid attach profile picture request")
	}
	userID := auth.GetUserID(ctx.Request.Header)
	return c.Repo.AttachProfilePicture(ctx, userID, contactID, req.AttachmentID, req.Size)
}

func (c *Controller) GetProfilePictureURL(ctx *gin.Context, contactID string) (*contactmodel.SignedURLResponse, error) {
	if !contactmodel.IsValidContactID(contactID) {
		return nil, ente.NewBadRequestWithMessage("invalid contact id")
	}
	userID := auth.GetUserID(ctx.Request.Header)
	entity, err := c.Repo.Get(ctx, userID, contactID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if entity.IsDeleted || entity.ProfilePictureAttachmentID == nil {
		return nil, &ente.ErrNotFoundError
	}
	attachment, err := c.Repo.GetAttachment(ctx, userID, *entity.ProfilePictureAttachmentID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if attachment.IsDeleted || attachment.AttachmentType != contactmodel.ProfilePicture {
		return nil, &ente.ErrNotFoundError
	}

	objectKey := contactmodel.AttachmentObjectKey(userID, attachment.AttachmentType, attachment.AttachmentID)
	s3Client := c.S3Config.GetS3Client(attachment.LatestBucket)
	input := &s3.GetObjectInput{
		Bucket:                     c.S3Config.GetBucket(attachment.LatestBucket),
		Key:                        aws.String(objectKey),
		ResponseContentDisposition: aws.String("attachment"),
	}
	getReq, _ := s3Client.GetObjectRequest(input)
	url, err := getReq.Presign(basecontroller.PreSignedRequestValidityDuration)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to presign profile picture download url")
	}
	return &contactmodel.SignedURLResponse{URL: url}, nil
}

func (c *Controller) DeleteProfilePicture(ctx *gin.Context, contactID string) (*contactmodel.Entity, error) {
	if !contactmodel.IsValidContactID(contactID) {
		return nil, ente.NewBadRequestWithMessage("invalid contact id")
	}
	userID := auth.GetUserID(ctx.Request.Header)
	return c.Repo.DeleteProfilePicture(ctx, userID, contactID)
}
