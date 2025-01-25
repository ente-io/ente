package controller

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/ente-io/museum/pkg/controller/discord"
	"github.com/ente-io/museum/pkg/utils/network"
	"runtime/debug"
	"strconv"
	"strings"

	"github.com/ente-io/museum/pkg/controller/email"
	"github.com/ente-io/museum/pkg/controller/lock"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/file"
	"github.com/ente-io/stacktrace"
	"github.com/gin-contrib/requestid"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/repo"
	enteArray "github.com/ente-io/museum/pkg/utils/array"
	"github.com/ente-io/museum/pkg/utils/s3config"
	"github.com/ente-io/museum/pkg/utils/time"
	log "github.com/sirupsen/logrus"
)

// FileController exposes functions to retrieve and access encrypted files
type FileController struct {
	FileRepo              *repo.FileRepository
	ObjectRepo            *repo.ObjectRepository
	ObjectCleanupRepo     *repo.ObjectCleanupRepository
	TrashRepository       *repo.TrashRepository
	UserRepo              *repo.UserRepository
	UsageCtrl             *UsageController
	CollectionRepo        *repo.CollectionRepository
	TaskLockingRepo       *repo.TaskLockRepository
	QueueRepo             *repo.QueueRepository
	S3Config              *s3config.S3Config
	ObjectCleanupCtrl     *ObjectCleanupController
	LockController        *lock.LockController
	EmailNotificationCtrl *email.EmailNotificationController
	DiscordController     *discord.DiscordController
	HostName              string
	cleanupCronRunning    bool
}

// StorageOverflowAboveSubscriptionLimit is the amount (50 MB) by which user can go beyond their storage limit
const StorageOverflowAboveSubscriptionLimit = int64(1024 * 1024 * 50)

// MaxFileSize is the maximum file size a user can upload
const MaxFileSize = int64(1024 * 1024 * 1024 * 5)

// MaxUploadURLsLimit indicates the max number of upload urls which can be request in one go
const MaxUploadURLsLimit = 50
const (
	DeletedObjectQueueLock = "deleted_objects_queue_lock"
)

func (c *FileController) validateFileCreateOrUpdateReq(userID int64, file ente.File) error {
	objectPathPrefix := strconv.FormatInt(userID, 10) + "/"
	if !strings.HasPrefix(file.File.ObjectKey, objectPathPrefix) || !strings.HasPrefix(file.Thumbnail.ObjectKey, objectPathPrefix) {
		return stacktrace.Propagate(ente.ErrBadRequest, "Incorrect object key reported")
	}
	if file.File.ObjectKey == file.Thumbnail.ObjectKey {
		return stacktrace.Propagate(ente.ErrBadRequest, "file and thumbnail object keys are same")
	}
	isCreateFileReq := file.ID == 0
	// Check for attributes for fileCreation. We don't send key details on update
	if isCreateFileReq {
		if file.EncryptedKey == "" || file.KeyDecryptionNonce == "" {
			return stacktrace.Propagate(ente.ErrBadRequest, "EncryptedKey and KeyDecryptionNonce are required")
		}
	}
	if file.File.DecryptionHeader == "" || file.Thumbnail.DecryptionHeader == "" {
		return stacktrace.Propagate(ente.ErrBadRequest, "DecryptionHeader for file & thumb is required")
	}
	if file.UpdationTime == 0 {
		return stacktrace.Propagate(ente.ErrBadRequest, "UpdationTime is required")
	}
	if isCreateFileReq {
		collection, err := c.CollectionRepo.Get(file.CollectionID)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		// Verify that user owns the collection.
		// Warning: Do not remove this check
		if collection.Owner.ID != userID {
			return stacktrace.Propagate(ente.ErrPermissionDenied, "collection doesn't belong to user")
		}
		if collection.IsDeleted {
			return stacktrace.Propagate(ente.ErrNotFound, "collection has been deleted")
		}
		if file.OwnerID != userID {
			return stacktrace.Propagate(ente.ErrPermissionDenied, "file ownerID doesn't match with userID")
		}
	}

	return nil
}

// Create adds an entry for a file in the respective tables
func (c *FileController) Create(ctx *gin.Context, userID int64, file ente.File, userAgent string, app ente.App) (ente.File, error) {
	err := c.validateFileCreateOrUpdateReq(userID, file)
	if err != nil {
		return file, stacktrace.Propagate(err, "")
	}
	hotDC := c.S3Config.GetHotDataCenter()
	// sizeOf will do also HEAD check to ensure that the object exists in the
	// current hot DC
	fileSize, err := c.sizeOf(file.File.ObjectKey)
	if err != nil {
		log.Error("Could not find size of file: " + file.File.ObjectKey)
		return file, stacktrace.Propagate(err, "")
	}
	if fileSize > MaxFileSize {
		return file, stacktrace.Propagate(ente.ErrFileTooLarge, "")
	}
	if file.File.Size != 0 && file.File.Size != fileSize {
		return file, stacktrace.Propagate(ente.ErrBadRequest, "mismatch in file size")
	}
	file.File.Size = fileSize
	thumbnailSize, err := c.sizeOf(file.Thumbnail.ObjectKey)
	if err != nil {
		log.Error("Could not find size of thumbnail: " + file.Thumbnail.ObjectKey)
		return file, stacktrace.Propagate(err, "")
	}
	if file.Thumbnail.Size != 0 && file.Thumbnail.Size != thumbnailSize {
		return file, stacktrace.Propagate(ente.ErrBadRequest, "mismatch in thumbnail size")
	}
	file.Thumbnail.Size = thumbnailSize
	var totalUploadSize = fileSize + thumbnailSize
	err = c.UsageCtrl.CanUploadFile(ctx, userID, &totalUploadSize, app)
	if err != nil {
		return file, stacktrace.Propagate(err, "")
	}

	file.Info = &ente.FileInfo{
		FileSize:      fileSize,
		ThumbnailSize: thumbnailSize,
	}

	// all iz well
	var usage int64
	file, usage, err = c.FileRepo.Create(file, fileSize, thumbnailSize, fileSize+thumbnailSize, userID, app)
	if err != nil {
		if err == ente.ErrDuplicateFileObjectFound || err == ente.ErrDuplicateThumbnailObjectFound {
			var existing ente.File
			if err == ente.ErrDuplicateFileObjectFound {
				existing, err = c.FileRepo.GetFileAttributesFromObjectKey(file.File.ObjectKey)
			} else {
				existing, err = c.FileRepo.GetFileAttributesFromObjectKey(file.Thumbnail.ObjectKey)
			}
			if err != nil {
				return file, stacktrace.Propagate(err, "")
			}
			file, err = c.onDuplicateObjectDetected(ctx, file, existing, hotDC)
			if err != nil {
				return file, stacktrace.Propagate(err, "")
			}
			return file, nil
		}
		return file, stacktrace.Propagate(err, "")
	}
	if usage == fileSize+thumbnailSize {
		go c.EmailNotificationCtrl.OnFirstFileUpload(file.OwnerID, userAgent)
	}
	return file, nil
}

// Update verifies permissions and updates the specified file
func (c *FileController) Update(ctx context.Context, userID int64, file ente.File, app ente.App) (ente.UpdateFileResponse, error) {
	var response ente.UpdateFileResponse
	err := c.validateFileCreateOrUpdateReq(userID, file)
	if err != nil {
		return response, stacktrace.Propagate(err, "")
	}
	ownerID, err := c.FileRepo.GetOwnerID(file.ID)
	if err != nil {
		return response, stacktrace.Propagate(err, "")
	}
	// verify that user owns the file
	if ownerID != userID {
		return response, stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
	file.OwnerID = ownerID
	existingFileObject, err := c.ObjectRepo.GetObject(file.ID, ente.FILE)
	if err != nil {
		return response, stacktrace.Propagate(err, "")
	}
	existingFileObjectKey := existingFileObject.ObjectKey
	oldFileSize := existingFileObject.FileSize
	existingThumbnailObject, err := c.ObjectRepo.GetObject(file.ID, ente.THUMBNAIL)
	if err != nil {
		return response, stacktrace.Propagate(err, "")
	}
	existingThumbnailObjectKey := existingThumbnailObject.ObjectKey
	oldThumbnailSize := existingThumbnailObject.FileSize
	fileSize, err := c.sizeOf(file.File.ObjectKey)
	if err != nil {
		return response, stacktrace.Propagate(err, "")
	}
	if fileSize > MaxFileSize {
		return response, stacktrace.Propagate(ente.ErrFileTooLarge, "")
	}
	if file.File.Size != 0 && file.File.Size != fileSize {
		return response, stacktrace.Propagate(ente.ErrBadRequest, "mismatch in file size")
	}
	thumbnailSize, err := c.sizeOf(file.Thumbnail.ObjectKey)
	if err != nil {
		return response, stacktrace.Propagate(err, "")
	}
	if file.Thumbnail.Size != 0 && file.Thumbnail.Size != thumbnailSize {
		return response, stacktrace.Propagate(ente.ErrBadRequest, "mismatch in thumbnail size")
	}
	diff := (fileSize + thumbnailSize) - (oldFileSize + oldThumbnailSize)
	err = c.UsageCtrl.CanUploadFile(ctx, userID, &diff, app)
	if err != nil {
		return response, stacktrace.Propagate(err, "")
	}
	// The client might retry updating the same file accidentally.
	//
	// This usually happens on iOS, where the first request to update a file
	// might succeed, but the client might go into the background before it gets
	// to know of it, and then retries again.
	//
	// As a safety check, also compare the file sizes.
	isDuplicateRequest := false
	if existingThumbnailObjectKey == file.Thumbnail.ObjectKey &&
		existingFileObjectKey == file.File.ObjectKey &&
		diff == 0 {
		isDuplicateRequest = true
	}
	oldObjects := make([]string, 0)
	if existingThumbnailObjectKey != file.Thumbnail.ObjectKey {
		// Ignore accidental retrials
		oldObjects = append(oldObjects, existingThumbnailObjectKey)
	}
	if existingFileObjectKey != file.File.ObjectKey {
		// Ignore accidental retrials
		oldObjects = append(oldObjects, existingFileObjectKey)
	}
	if file.Info != nil {
		file.Info.FileSize = fileSize
		file.Info.ThumbnailSize = thumbnailSize
	} else {
		file.Info = &ente.FileInfo{
			FileSize:      fileSize,
			ThumbnailSize: thumbnailSize,
		}
	}
	err = c.FileRepo.Update(file, fileSize, thumbnailSize, diff, oldObjects, isDuplicateRequest)
	if err != nil {
		return response, stacktrace.Propagate(err, "")
	}
	response.ID = file.ID
	response.UpdationTime = file.UpdationTime
	return response, nil
}

// GetUploadURLs returns a bunch of presigned URLs for uploading files
func (c *FileController) GetUploadURLs(ctx context.Context, userID int64, count int, app ente.App, ignoreLimit bool) ([]ente.UploadURL, error) {
	err := c.UsageCtrl.CanUploadFile(ctx, userID, nil, app)
	if err != nil {
		return []ente.UploadURL{}, stacktrace.Propagate(err, "")
	}
	s3Client := c.S3Config.GetHotS3Client()
	dc := c.S3Config.GetHotDataCenter()
	bucket := c.S3Config.GetHotBucket()
	urls := make([]ente.UploadURL, 0)
	objectKeys := make([]string, 0)
	if count > MaxUploadURLsLimit && !ignoreLimit {
		count = MaxUploadURLsLimit
	}
	for i := 0; i < count; i++ {
		objectKey := strconv.FormatInt(userID, 10) + "/" + uuid.NewString()
		objectKeys = append(objectKeys, objectKey)
		url, err := c.getObjectURL(s3Client, dc, bucket, objectKey)
		if err != nil {
			return urls, stacktrace.Propagate(err, "")
		}
		urls = append(urls, url)
	}
	log.Print("Returning objectKeys: " + strings.Join(objectKeys, ", "))
	return urls, nil
}

// GetFileURL verifies permissions and returns a presigned url to the requested file
func (c *FileController) GetFileURL(ctx *gin.Context, userID int64, fileID int64) (string, error) {
	err := c.verifyFileAccess(userID, fileID)
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	url, err := c.getSignedURLForType(ctx, fileID, ente.FILE)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			go c.CleanUpStaleCollectionFiles(userID, fileID)
		}
		return "", stacktrace.Propagate(err, "")
	}
	return url, nil
}

// GetThumbnailURL verifies permissions and returns a presigned url to the requested thumbnail
func (c *FileController) GetThumbnailURL(ctx *gin.Context, userID int64, fileID int64) (string, error) {
	err := c.verifyFileAccess(userID, fileID)
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	url, err := c.getSignedURLForType(ctx, fileID, ente.THUMBNAIL)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			go c.CleanUpStaleCollectionFiles(userID, fileID)
		}
		return "", stacktrace.Propagate(err, "")
	}
	return url, nil
}

func (c *FileController) CleanUpStaleCollectionFiles(userID int64, fileID int64) {
	logger := log.WithFields(log.Fields{
		"userID": userID,
		"fileID": fileID,
		"action": "CleanUpStaleCollectionFiles",
	})
	// catch panic
	defer func() {
		if r := recover(); r != nil {
			logger.Error("Recovered from panic", r)
		}
	}()
	fileIDs := make([]int64, 0)
	fileIDs = append(fileIDs, fileID)

	// verify file ownership
	err := c.FileRepo.VerifyFileOwner(context.Background(), fileIDs, userID, logger)

	if err != nil {
		logger.Warning("Failed to verify file ownership", err)
		return
	}
	err = c.TrashRepository.CleanUpDeletedFilesFromCollection(context.Background(), fileIDs, userID)
	if err != nil {
		logger.WithError(err).Error("Failed to clean up stale files from collection")
	}

}

// GetPublicFileURL verifies permissions and returns a presigned url to the requested file
func (c *FileController) GetPublicFileURL(ctx *gin.Context, fileID int64, objType ente.ObjectType) (string, error) {
	accessContext := auth.MustGetPublicAccessContext(ctx)
	accessible, err := c.CollectionRepo.DoesFileExistInCollections(fileID, []int64{accessContext.CollectionID})
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	if !accessible {
		return "", stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
	return c.getSignedURLForType(ctx, fileID, objType)
}

// GetCastFileUrl verifies permissions and returns a presigned url to the requested file
func (c *FileController) GetCastFileUrl(ctx *gin.Context, fileID int64, objType ente.ObjectType) (string, error) {
	castCtx := auth.GetCastCtx(ctx)
	accessible, err := c.CollectionRepo.DoesFileExistInCollections(fileID, []int64{castCtx.CollectionID})
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	if !accessible {
		return "", stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
	return c.getSignedURLForType(ctx, fileID, objType)
}

func (c *FileController) getSignedURLForType(ctx *gin.Context, fileID int64, objType ente.ObjectType) (string, error) {
	if isCliRequest(ctx) {
		return c.getWasabiSignedUrlIfAvailable(fileID, objType)
	}
	s3Object, err := c.ObjectRepo.GetObject(fileID, objType)
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	return c.getHotDcSignedUrl(s3Object.ObjectKey)
}

// ignore lint unused inspection
func isCliRequest(ctx *gin.Context) bool {
	// todo: (neeraj) remove this short-circuit after wasabi migration
	return false
	// check if user-agent contains go-resty
	//userAgent := ctx.Request.Header.Get("User-Agent")
	//return strings.Contains(userAgent, "go-resty")

}

// getWasabiSignedUrlIfAvailable returns a signed URL for the given fileID and objectType. It prefers wasabi over b2
// if the file is not found in wasabi, it will return signed url from B2
func (c *FileController) getWasabiSignedUrlIfAvailable(fileID int64, objType ente.ObjectType) (string, error) {
	s3Object, dcs, err := c.ObjectRepo.GetObjectWithDCs(fileID, objType)
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	for _, dc := range dcs {
		if dc == c.S3Config.GetHotWasabiDC() {
			return c.getPreSignedURLForDC(s3Object.ObjectKey, dc)
		}
	}
	// todo: (neeraj) remove this log after some time
	log.WithFields(log.Fields{
		"fileID": fileID}).Info("File not found in wasabi, returning signed url from B2")
	// return signed url from default hot bucket
	return c.getHotDcSignedUrl(s3Object.ObjectKey)
}

// Trash deletes file and move them to trash
func (c *FileController) Trash(ctx *gin.Context, userID int64, request ente.TrashRequest) error {
	fileIDs := make([]int64, 0)
	collectionIDs := make([]int64, 0)
	for _, trashItem := range request.TrashItems {
		fileIDs = append(fileIDs, trashItem.FileID)
		collectionIDs = append(collectionIDs, trashItem.CollectionID)
	}
	if enteArray.ContainsDuplicateInInt64Array(fileIDs) {
		return stacktrace.Propagate(ente.ErrBadRequest, "duplicate fileIDs")
	}
	if err := c.VerifyFileOwnership(ctx, userID, fileIDs); err != nil {
		return stacktrace.Propagate(err, "")
	}
	uniqueCollectionIDs := enteArray.UniqueInt64(collectionIDs)
	for _, collectionID := range uniqueCollectionIDs {
		ownerID, err := c.CollectionRepo.GetOwnerID(collectionID)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		if ownerID != userID {
			return stacktrace.Propagate(ente.ErrPermissionDenied, "user doesn't own collection")
		}
	}
	return c.TrashRepository.TrashFiles(fileIDs, userID, request)
}

// GetSize returns the size of files indicated by fileIDs that are owned by userID
func (c *FileController) GetSize(userID int64, fileIDs []int64) (int64, error) {
	size, err := c.FileRepo.GetSize(userID, fileIDs)
	if err != nil {
		return -1, stacktrace.Propagate(err, "")
	}
	return size, nil
}

// GetFileInfo returns the file infos given list of files
func (c *FileController) GetFileInfo(ctx *gin.Context, userID int64, fileIDs []int64) (*ente.FilesInfoResponse, error) {
	logger := log.WithFields(log.Fields{
		"req_id": requestid.Get(ctx),
	})
	err := c.FileRepo.VerifyFileOwner(ctx, fileIDs, userID, logger)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	// Use GetFilesInfo for get fileInfo for the given list.
	// Then for fileIDs that are not present in the response of GetFilesInfo, use GetFileInfoFromObjectKeys to get the file info.
	// and merge the two responses. and for the fileIDs that are not present in the response of GetFileInfoFromObjectKeys,
	// add a new FileInfo entry with size = -1
	fileInfoResponse, err := c.FileRepo.GetFilesInfo(ctx, fileIDs, userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	fileIDsNotPresentInFilesDB := make([]int64, 0)
	for _, fileID := range fileIDs {
		if val, ok := fileInfoResponse[fileID]; !ok || val == nil {
			fileIDsNotPresentInFilesDB = append(fileIDsNotPresentInFilesDB, fileID)
		}
	}
	if len(fileIDsNotPresentInFilesDB) > 0 {
		logger.WithField("count", len(fileIDsNotPresentInFilesDB)).Info("fileInfos are not present in files table, fetching from object keys")
		fileInfoResponseFromObjectKeys, err := c.FileRepo.GetFileInfoFromObjectKeys(ctx, fileIDsNotPresentInFilesDB)
		if err != nil {
			return nil, stacktrace.Propagate(err, "")
		}
		err = c.FileRepo.UpdateSizeInfo(ctx, fileInfoResponseFromObjectKeys)

		if err != nil {
			return nil, stacktrace.Propagate(err, "Failed to update the size info in files")
		}

		for id, fileInfo := range fileInfoResponseFromObjectKeys {
			fileInfoResponse[id] = fileInfo
		}
	}
	missedFileIDs := make([]int64, 0)
	for _, fileID := range fileIDs {
		if _, ok := fileInfoResponse[fileID]; !ok {
			missedFileIDs = append(missedFileIDs, fileID)
		}
	}
	if len(missedFileIDs) > 0 {
		return nil, stacktrace.Propagate(ente.NewInternalError("failed to get fileInfo"), "fileIDs not found: %v", missedFileIDs)
	}

	// prepare a list of FileInfoResponse
	fileInfoList := make([]*ente.FileInfoResponse, 0)
	for _, fileID := range fileIDs {
		id := fileID
		fileInfo := fileInfoResponse[id]
		if fileInfo == nil {
			// This should be happening only for older users who may have a stale
			// collection_file entry for a file that user has deleted
			log.WithField("fileID", id).Error("fileInfo not found")
			fileInfoList = append(fileInfoList, &ente.FileInfoResponse{
				ID:       id,
				FileInfo: ente.FileInfo{FileSize: -1, ThumbnailSize: -1},
			})
		} else {
			fileInfoList = append(fileInfoList, &ente.FileInfoResponse{
				ID:       id,
				FileInfo: *fileInfo,
			})
		}
	}
	return &ente.FilesInfoResponse{
		FilesInfo: fileInfoList,
	}, nil
}

// GetDuplicates returns the list of files of the same size
func (c *FileController) GetDuplicates(userID int64) ([]ente.DuplicateFiles, error) {
	dupes, err := c.FileRepo.GetDuplicateFiles(userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return dupes, nil
}

// GetLargeThumbnailFiles returns the list of files whose thumbnail size is larger than threshold size
func (c *FileController) GetLargeThumbnailFiles(userID int64, threshold int64) ([]int64, error) {
	largeThumbnailFiles, err := c.FileRepo.GetLargeThumbnailFiles(userID, threshold)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return largeThumbnailFiles, nil
}

// UpdateMagicMetadata updates the magic metadata for list of files
func (c *FileController) UpdateMagicMetadata(ctx *gin.Context, req ente.UpdateMultipleMagicMetadataRequest, isPublicMetadata bool) error {
	err := c.validateUpdateMetadataRequest(ctx, req, isPublicMetadata)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	err = c.FileRepo.UpdateMagicAttributes(ctx, req.MetadataList, isPublicMetadata, req.SkipVersion)
	if err != nil {
		return stacktrace.Propagate(err, "failed to update magic attributes")
	}
	return nil
}

// UpdateThumbnail updates thumbnail of a file
func (c *FileController) UpdateThumbnail(ctx *gin.Context, fileID int64, newThumbnail ente.FileAttributes, app ente.App) error {
	userID := auth.GetUserID(ctx.Request.Header)
	objectPathPrefix := strconv.FormatInt(userID, 10) + "/"
	if !strings.HasPrefix(newThumbnail.ObjectKey, objectPathPrefix) {
		return stacktrace.Propagate(ente.ErrBadRequest, "Incorrect object key reported")
	}
	ownerID, err := c.FileRepo.GetOwnerID(fileID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	// verify that user owns the file
	if ownerID != userID {
		return stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
	existingThumbnailObject, err := c.ObjectRepo.GetObject(fileID, ente.THUMBNAIL)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	existingThumbnailObjectKey := existingThumbnailObject.ObjectKey
	oldThumbnailSize := existingThumbnailObject.FileSize
	newThumbnailSize, err := c.sizeOf(newThumbnail.ObjectKey)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	diff := newThumbnailSize - oldThumbnailSize
	if diff > 0 {
		return stacktrace.Propagate(errors.New("new thumbnail larger than existing thumbnail"), "")
	}
	err = c.UsageCtrl.CanUploadFile(ctx, userID, &diff, app)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	var oldObject *string
	if existingThumbnailObjectKey != newThumbnail.ObjectKey {
		// delete old object only if newThumbnail object key different.
		oldObject = &existingThumbnailObjectKey
	}
	err = c.FileRepo.UpdateThumbnail(ctx, fileID, userID, newThumbnail, newThumbnailSize, diff, oldObject)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

// VerifyFileOwnership will return error if given fileIDs are not valid or don't belong to the ownerID
func (c *FileController) VerifyFileOwnership(ctx *gin.Context, ownerID int64, fileIDs []int64) error {
	countMap, err := c.FileRepo.GetOwnerToFileCountMap(ctx, fileIDs)
	if err != nil {
		return stacktrace.Propagate(err, "failed to get owners info")
	}
	logger := log.WithFields(log.Fields{
		"req_id":     requestid.Get(ctx),
		"owner_id":   ownerID,
		"file_ids":   fileIDs,
		"owners_map": countMap,
	})
	if len(countMap) == 0 {
		logger.Error("all fileIDs are invalid")
		return stacktrace.Propagate(ente.ErrBadRequest, "")
	}
	if len(countMap) > 1 {
		logger.Error("files are owned by multiple users")
		return stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
	if filesOwned, ok := countMap[ownerID]; ok {
		if filesOwned != int64(len(fileIDs)) {
			logger.WithField("file_owned", filesOwned).Error("failed to find all fileIDs")
			return stacktrace.Propagate(ente.ErrBadRequest, "")
		}
		return nil
	} else {
		logger.Error("user is not an owner of any file")
		return stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
}

func (c *FileController) validateUpdateMetadataRequest(ctx *gin.Context, req ente.UpdateMultipleMagicMetadataRequest, isPublicMetadata bool) error {
	userID := auth.GetUserID(ctx.Request.Header)
	for _, updateMMdRequest := range req.MetadataList {
		ownerID, existingMetadata, err := c.FileRepo.GetOwnerAndMagicMetadata(updateMMdRequest.ID, isPublicMetadata)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		if ownerID != userID {
			log.WithFields(log.Fields{
				"file_id":   updateMMdRequest.ID,
				"owner_id":  ownerID,
				"user_id":   userID,
				"public_md": isPublicMetadata,
			}).Error("can't update magic metadata for file which isn't owned by use")
			return stacktrace.Propagate(ente.ErrPermissionDenied, "")
		}
		oldToNewCountDiff := 0
		if existingMetadata != nil {
			oldToNewCountDiff = existingMetadata.Count - updateMMdRequest.MagicMetadata.Count
		}
		// Return an error if there is a version mismatch with the previous metadata
		// or if the new metadata contains an unexpectedly lower number of keys
		// (oldToNewCountDiff difference is > 2), which may indicate potential data loss due to potentially buggy client.
		if existingMetadata != nil && (existingMetadata.Version != updateMMdRequest.MagicMetadata.Version || oldToNewCountDiff > 2) {
			log.WithFields(log.Fields{
				"existing_count":   existingMetadata.Count,
				"existing_version": existingMetadata.Version,
				"file_id":          updateMMdRequest.ID,
				"received_count":   updateMMdRequest.MagicMetadata.Count,
				"received_version": updateMMdRequest.MagicMetadata.Version,
				"public_md":        isPublicMetadata,
			}).Error("invalid ops: mismatch in metadata version or count")
			return stacktrace.Propagate(ente.ErrVersionMismatch, "mismatch in metadata version or count")
		}
	}
	return nil
}

// CleanupDeletedFiles deletes the files from object store. It will delete from both hot storage and
// cold storage (if replicated)
func (c *FileController) CleanupDeletedFiles() {
	log.Info("Cleaning up deleted files")
	// If cleanup is already running, avoiding concurrent runs to avoid concurrent issues
	if c.cleanupCronRunning {
		log.Info("Skipping CleanupDeletedFiles cron run as another instance is still running")
		return
	}
	c.cleanupCronRunning = true
	defer func() {
		c.cleanupCronRunning = false
	}()

	lockStatus := c.LockController.TryLock(DeletedObjectQueueLock, time.MicrosecondsAfterHours(2))
	if !lockStatus {
		log.Warning(fmt.Sprintf("Failed to acquire lock %s", DeletedObjectQueueLock))
		return
	}
	defer func() {
		c.LockController.ReleaseLock(DeletedObjectQueueLock)
	}()
	items, err := c.QueueRepo.GetItemsReadyForDeletion(repo.DeleteObjectQueue, 1500)
	if err != nil {
		log.WithError(err).Error("Failed to fetch items from queue")
		return
	}
	for _, i := range items {
		c.cleanupDeletedFile(i)
	}
}

func (c *FileController) GetTotalFileCount() (int64, error) {
	count, err := c.FileRepo.GetTotalFileCount()
	if err != nil {
		return -1, stacktrace.Propagate(err, "")
	}
	return count, nil
}

func (c *FileController) cleanupDeletedFile(qItem repo.QueueItem) {
	lockName := file.GetLockNameForObject(qItem.Item)
	lockStatus, err := c.TaskLockingRepo.AcquireLock(lockName, time.MicrosecondsAfterHours(1), c.HostName)
	ctxLogger := log.WithField("item", qItem.Item).WithField("queue_id", qItem.Id)
	if err != nil || !lockStatus {
		ctxLogger.Warn("unable to acquire lock")
		return
	}
	defer func() {
		err = c.TaskLockingRepo.ReleaseLock(lockName)
		if err != nil {
			ctxLogger.Errorf("Error while releasing lock %s", err)
		}
	}()
	ctxLogger.Info("Deleting item")
	dcs, err := c.ObjectRepo.GetDataCentersForObject(qItem.Item)
	if err != nil {
		ctxLogger.Errorf("Could not fetch datacenters %s", err)
		return
	}
	for _, dc := range dcs {
		if c.S3Config.ShouldDeleteFromDataCenter(dc) {
			err = c.ObjectCleanupCtrl.DeleteObjectFromDataCenter(qItem.Item, dc)
		}
		if err != nil {
			ctxLogger.WithError(err).Error("Failed to delete " + qItem.Item + " from " + dc)
			return
		}
		err = c.ObjectRepo.RemoveDataCenterFromObject(qItem.Item, dc)
		if err != nil {
			ctxLogger.WithError(err).Error("Could not remove from table: " + qItem.Item + ", dc: " + dc)
			return
		}
	}
	err = c.ObjectRepo.RemoveObjectsForKey(qItem.Item)
	if err != nil {
		ctxLogger.WithError(err).Error("Failed to remove item from object_keys")
		return
	}
	err = c.QueueRepo.DeleteItem(repo.DeleteObjectQueue, qItem.Item)
	if err != nil {
		ctxLogger.WithError(err).Error("Failed to remove item from the queue")
		return
	}
	ctxLogger.Info("Successfully deleted item")
}

func (c *FileController) getHotDcSignedUrl(objectKey string) (string, error) {
	s3Client := c.S3Config.GetHotS3Client()
	r, _ := s3Client.GetObjectRequest(&s3.GetObjectInput{
		Bucket: c.S3Config.GetHotBucket(),
		Key:    &objectKey,
	})
	return r.Presign(PreSignedRequestValidityDuration)
}

func (c *FileController) getPreSignedURLForDC(objectKey string, dc string) (string, error) {
	s3Client := c.S3Config.GetS3Client(dc)
	r, _ := s3Client.GetObjectRequest(&s3.GetObjectInput{
		Bucket: c.S3Config.GetBucket(dc),
		Key:    &objectKey,
	})
	return r.Presign(PreSignedRequestValidityDuration)
}

func (c *FileController) sizeOf(objectKey string) (int64, error) {
	s3Client := c.S3Config.GetHotS3Client()
	head, err := s3Client.HeadObject(&s3.HeadObjectInput{
		Key:    &objectKey,
		Bucket: c.S3Config.GetHotBucket(),
	})
	if err != nil {
		return -1, stacktrace.Propagate(err, "")
	}
	return *head.ContentLength, nil
}

func (c *FileController) onDuplicateObjectDetected(ctx *gin.Context, file ente.File, existing ente.File, hotDC string) (ente.File, error) {
	newJSON, _ := json.Marshal(file)
	existingJSON, _ := json.Marshal(existing)
	log.Info("Comparing " + string(newJSON) + " against " + string(existingJSON))
	if file.Thumbnail.ObjectKey == existing.Thumbnail.ObjectKey &&
		file.Thumbnail.Size == existing.Thumbnail.Size &&
		file.Thumbnail.DecryptionHeader == existing.Thumbnail.DecryptionHeader &&
		file.File.ObjectKey == existing.File.ObjectKey &&
		file.File.Size == existing.File.Size &&
		file.File.DecryptionHeader == existing.File.DecryptionHeader &&
		file.Metadata.EncryptedData == existing.Metadata.EncryptedData &&
		file.Metadata.DecryptionHeader == existing.Metadata.DecryptionHeader &&
		file.OwnerID == existing.OwnerID {
		// Already uploaded file
		file.ID = existing.ID
		return file, nil
	} else {
		// Overwrote an existing file or thumbnail
		go c.onExistingObjectsReplaced(ctx, file, hotDC)
		return ente.File{}, ente.ErrBadRequest
	}
}

func (c *FileController) safeAlert(msg string) {
	defer func() {
		if r := recover(); r != nil {
			log.Errorf("Panic caught: %s, stack: %s", r, string(debug.Stack()))
		}
	}()
	c.DiscordController.Notify(msg)
}

func (c *FileController) onExistingObjectsReplaced(ctx *gin.Context, file ente.File, hotDC string) {
	defer func() {
		if r := recover(); r != nil {
			log.Errorf("Panic caught: %s, stack: %s", r, string(debug.Stack()))
		}
	}()
	client := network.GetClientInfo(ctx)
	reqId := requestid.Get(ctx)
	revertErr := false
	go c.safeAlert(fmt.Sprintf(`Client %s replaced an existing object req_id %s for (file: %s, thum %s)`, client, reqId, file.File.ObjectKey, file.Thumbnail.ObjectKey))
	log.Error("Replaced existing object, reverting", file)
	logger := log.WithFields(log.Fields{
		"req_id":    reqId,
		"owner_id":  file.OwnerID,
		"file_obj":  file.File.ObjectKey,
		"fileSize":  file.File.Size,
		"thumb_obj": file.Thumbnail.ObjectKey,
		"thumbSize": file.Thumbnail.Size,
	})

	err := c.rollbackObject(file.File.ObjectKey)
	if err != nil {
		logger.Error("Error rolling back latest file from hot storage", err)
		revertErr = true
	}
	err = c.rollbackObject(file.Thumbnail.ObjectKey)
	if err != nil {
		log.Error("Error rolling back latest thumbnail from hot storage", err)
		revertErr = true
	}
	resetErr := c.FileRepo.ResetNeedsReplication(file, hotDC)
	if resetErr != nil {
		log.Error("Error resetting needs replication", resetErr)
		revertErr = true
	}
	if revertErr {
		go c.safeAlert(fmt.Sprintf(`☠️ Client %s replaced an existing object req_id %s for user %d, failed to revert`, client, reqId, file.OwnerID))
	} else {
		go c.safeAlert(fmt.Sprintf(`🔄 Client %s replaced an existing object req_id %s for user %d, reverted`, client, reqId, file.OwnerID))
	}
}

func (c *FileController) rollbackObject(objectKey string) error {
	versions, err := c.getVersions(objectKey)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if len(versions) > 1 {
		err = c.deleteObjectVersionFromHotStorage(objectKey,
			*versions[0].VersionId)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
	}
	return nil
}

func (c *FileController) getVersions(objectKey string) ([]*s3.ObjectVersion, error) {
	s3Client := c.S3Config.GetHotS3Client()
	response, err := s3Client.ListObjectVersions(&s3.ListObjectVersionsInput{
		Prefix: &objectKey,
		Bucket: c.S3Config.GetHotBucket(),
	})
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return response.Versions, nil
}

func (c *FileController) deleteObjectVersionFromHotStorage(objectKey string, versionID string) error {
	var s3Client = c.S3Config.GetHotS3Client()
	_, err := s3Client.DeleteObject(&s3.DeleteObjectInput{
		Bucket:    c.S3Config.GetHotBucket(),
		Key:       &objectKey,
		VersionId: &versionID,
	})
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	err = s3Client.WaitUntilObjectNotExists(&s3.HeadObjectInput{
		Bucket: c.S3Config.GetHotBucket(),
		Key:    &objectKey,
	})
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

func (c *FileController) verifyFileAccess(actorUserID int64, fileID int64) error {
	fileOwnerID, err := c.FileRepo.GetOwnerID(fileID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}

	if fileOwnerID != actorUserID {
		cIDs, err := c.CollectionRepo.GetCollectionIDsSharedWithUser(actorUserID)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		cwIDS, err := c.CollectionRepo.GetCollectionIDsSharedWithUser(fileOwnerID)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		cIDs = append(cIDs, cwIDS...)

		accessible, err := c.CollectionRepo.DoesFileExistInCollections(fileID, cIDs)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		if !accessible {
			return stacktrace.Propagate(ente.ErrPermissionDenied, "")
		}
	}
	return nil
}

func (c *FileController) getObjectURL(s3Client *s3.S3, dc string, bucket *string, objectKey string) (ente.UploadURL, error) {
	r, _ := s3Client.PutObjectRequest(&s3.PutObjectInput{
		Bucket: bucket,
		Key:    &objectKey,
	})
	url, err := r.Presign(PreSignedRequestValidityDuration)
	if err != nil {
		return ente.UploadURL{}, stacktrace.Propagate(err, "")
	}
	err = c.ObjectCleanupCtrl.AddTempObjectKey(objectKey, dc)
	if err != nil {
		return ente.UploadURL{}, stacktrace.Propagate(err, "")
	}
	return ente.UploadURL{ObjectKey: objectKey, URL: url}, nil
}

// GetMultipartUploadURLs return collections of url to upload the parts of the files
func (c *FileController) GetMultipartUploadURLs(ctx context.Context, userID int64, count int, app ente.App) (ente.MultipartUploadURLs, error) {
	err := c.UsageCtrl.CanUploadFile(ctx, userID, nil, app)
	if err != nil {
		return ente.MultipartUploadURLs{}, stacktrace.Propagate(err, "")
	}
	s3Client := c.S3Config.GetHotS3Client()
	dc := c.S3Config.GetHotDataCenter()
	bucket := c.S3Config.GetHotBucket()
	objectKey := strconv.FormatInt(userID, 10) + "/" + uuid.NewString()
	r, err := s3Client.CreateMultipartUpload(&s3.CreateMultipartUploadInput{
		Bucket: bucket,
		Key:    &objectKey,
	})
	if err != nil {
		return ente.MultipartUploadURLs{}, stacktrace.Propagate(err, "")
	}
	err = c.ObjectCleanupCtrl.AddMultipartTempObjectKey(objectKey, *r.UploadId, dc)
	if err != nil {
		return ente.MultipartUploadURLs{}, stacktrace.Propagate(err, "")
	}
	multipartUploadURLs := ente.MultipartUploadURLs{ObjectKey: objectKey}
	urls := make([]string, 0)
	for i := 0; i < count; i++ {
		url, err := c.getPartURL(*s3Client, objectKey, int64(i+1), r.UploadId)
		if err != nil {
			return multipartUploadURLs, stacktrace.Propagate(err, "")
		}
		urls = append(urls, url)
	}
	multipartUploadURLs.PartURLs = urls
	r2, _ := s3Client.CompleteMultipartUploadRequest(&s3.CompleteMultipartUploadInput{
		Bucket:   c.S3Config.GetHotBucket(),
		Key:      &objectKey,
		UploadId: r.UploadId,
	})
	url, err := r2.Presign(PreSignedRequestValidityDuration)
	if err != nil {
		return multipartUploadURLs, stacktrace.Propagate(err, "")
	}
	multipartUploadURLs.CompleteURL = url

	return multipartUploadURLs, nil
}

func (c *FileController) getPartURL(s3Client s3.S3, objectKey string, partNumber int64, uploadID *string) (string, error) {
	r, _ := s3Client.UploadPartRequest(&s3.UploadPartInput{
		Bucket:     c.S3Config.GetHotBucket(),
		Key:        &objectKey,
		UploadId:   uploadID,
		PartNumber: &partNumber,
	})
	url, err := r.Presign(PreSignedPartUploadRequestDuration)
	if err != nil {
		return "", stacktrace.Propagate(err, "")
	}
	return url, nil
}
