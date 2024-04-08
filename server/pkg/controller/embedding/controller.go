package embedding

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/ente-io/museum/pkg/utils/array"
	"strconv"
	"sync"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/controller/access"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/repo/embedding"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/network"
	"github.com/ente-io/museum/pkg/utils/s3config"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

type Controller struct {
	Repo                    *embedding.Repository
	AccessCtrl              access.Controller
	ObjectCleanupController *controller.ObjectCleanupController
	S3Config                *s3config.S3Config
	QueueRepo               *repo.QueueRepository
	TaskLockingRepo         *repo.TaskLockRepository
	FileRepo                *repo.FileRepository
	CollectionRepo          *repo.CollectionRepository
	HostName                string
	cleanupCronRunning      bool
}

func (c *Controller) InsertOrUpdate(ctx *gin.Context, req ente.InsertOrUpdateEmbeddingRequest) (*ente.Embedding, error) {
	userID := auth.GetUserID(ctx.Request.Header)

	err := c.AccessCtrl.VerifyFileOwnership(ctx, &access.VerifyFileOwnershipParams{
		ActorUserId: userID,
		FileIDs:     []int64{req.FileID},
	})

	if err != nil {
		return nil, stacktrace.Propagate(err, "User does not own file")
	}

	count, err := c.CollectionRepo.GetCollectionCount(req.FileID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if count < 1 {
		return nil, stacktrace.Propagate(ente.ErrNotFound, "")
	}
	version := 1
	if req.Version != nil {
		version = *req.Version
	}

	obj := ente.EmbeddingObject{
		Version:            version,
		EncryptedEmbedding: req.EncryptedEmbedding,
		DecryptionHeader:   req.DecryptionHeader,
		Client:             network.GetPrettyUA(ctx.GetHeader("User-Agent")) + "/" + ctx.GetHeader("X-Client-Version"),
	}
	size, uploadErr := c.uploadObject(obj, c.getObjectKey(userID, req.FileID, req.Model))
	if uploadErr != nil {
		log.Error(uploadErr)
		return nil, stacktrace.Propagate(uploadErr, "")
	}
	embedding, err := c.Repo.InsertOrUpdate(ctx, userID, req, size, version)
	embedding.Version = &version
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &embedding, nil
}

func (c *Controller) GetDiff(ctx *gin.Context, req ente.GetEmbeddingDiffRequest) ([]ente.Embedding, error) {
	userID := auth.GetUserID(ctx.Request.Header)

	if req.Model == "" {
		req.Model = ente.GgmlClip
	}

	embeddings, err := c.Repo.GetDiff(ctx, userID, req.Model, *req.SinceTime, req.Limit)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	// Collect object keys for embeddings with missing data
	var objectKeys []string
	for i := range embeddings {
		if embeddings[i].EncryptedEmbedding == "" {
			objectKey := c.getObjectKey(userID, embeddings[i].FileID, embeddings[i].Model)
			objectKeys = append(objectKeys, objectKey)
		}
	}

	// Fetch missing embeddings in parallel
	if len(objectKeys) > 0 {
		embeddingObjects, err := c.getEmbeddingObjectsParallel(objectKeys)
		if err != nil {
			return nil, stacktrace.Propagate(err, "")
		}

		// Populate missing data in embeddings from fetched objects
		for i, obj := range embeddingObjects {
			for j := range embeddings {
				if embeddings[j].EncryptedEmbedding == "" && c.getObjectKey(userID, embeddings[j].FileID, embeddings[j].Model) == objectKeys[i] {
					embeddings[j].EncryptedEmbedding = obj.EncryptedEmbedding
					embeddings[j].DecryptionHeader = obj.DecryptionHeader
				}
			}
		}
	}

	return embeddings, nil
}

func (c *Controller) GetFilesEmbedding(ctx *gin.Context, req ente.GetFilesEmbeddingRequest) (*ente.GetFilesEmbeddingResponse, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	if err := c._validateGetFileEmbeddingsRequest(ctx, userID, req); err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	userFileEmbeddings, err := c.Repo.GetFilesEmbedding(ctx, userID, req.Model, req.FileIDs)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	dbFileIds := make([]int64, 0)
	for _, embedding := range userFileEmbeddings {
		dbFileIds = append(dbFileIds, embedding.FileID)
	}
	missingFileIds := array.FindMissingElementsInSecondList(req.FileIDs, dbFileIds)
	errFileIds := make([]int64, 0)

	// Fetch missing userFileEmbeddings in parallel
	embeddingObjects, err := c.getEmbeddingObjectsParallelV2(userID, userFileEmbeddings)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	fetchedEmbeddings := make([]ente.Embedding, 0)

	// Populate missing data in userFileEmbeddings from fetched objects
	for _, obj := range embeddingObjects {
		if obj.err != nil {
			errFileIds = append(errFileIds, obj.dbEmbeddingRow.FileID)
		} else {
			fetchedEmbeddings = append(fetchedEmbeddings, ente.Embedding{
				FileID:             obj.dbEmbeddingRow.FileID,
				Model:              obj.dbEmbeddingRow.Model,
				EncryptedEmbedding: obj.embeddingObject.EncryptedEmbedding,
				DecryptionHeader:   obj.embeddingObject.DecryptionHeader,
				UpdatedAt:          obj.dbEmbeddingRow.UpdatedAt,
				Version:            obj.dbEmbeddingRow.Version,
			})
		}
	}

	return &ente.GetFilesEmbeddingResponse{
		Embeddings:    fetchedEmbeddings,
		NoDataFileIDs: missingFileIds,
		ErrFileIDs:    errFileIds,
	}, nil
}

func (c *Controller) DeleteAll(ctx *gin.Context) error {
	userID := auth.GetUserID(ctx.Request.Header)

	err := c.Repo.DeleteAll(ctx, userID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

// CleanupDeletedEmbeddings clears all embeddings for deleted files from the object store
func (c *Controller) CleanupDeletedEmbeddings() {
	log.Info("Cleaning up deleted embeddings")
	if c.cleanupCronRunning {
		log.Info("Skipping CleanupDeletedEmbeddings cron run as another instance is still running")
		return
	}
	c.cleanupCronRunning = true
	defer func() {
		c.cleanupCronRunning = false
	}()
	items, err := c.QueueRepo.GetItemsReadyForDeletion(repo.DeleteEmbeddingsQueue, 200)
	if err != nil {
		log.WithError(err).Error("Failed to fetch items from queue")
		return
	}
	for _, i := range items {
		c.deleteEmbedding(i)
	}
}

func (c *Controller) deleteEmbedding(qItem repo.QueueItem) {
	lockName := fmt.Sprintf("Embedding:%s", qItem.Item)
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
	ctxLogger.Info("Deleting all embeddings")

	fileID, _ := strconv.ParseInt(qItem.Item, 10, 64)
	ownerID, err := c.FileRepo.GetOwnerID(fileID)
	if err != nil {
		ctxLogger.WithError(err).Error("Failed to fetch ownerID")
		return
	}
	prefix := c.getEmbeddingObjectPrefix(ownerID, fileID)

	err = c.ObjectCleanupController.DeleteAllObjectsWithPrefix(prefix, c.S3Config.GetHotDataCenter())
	if err != nil {
		ctxLogger.WithError(err).Error("Failed to delete all objects")
		return
	}

	err = c.Repo.Delete(fileID)
	if err != nil {
		ctxLogger.WithError(err).Error("Failed to remove from db")
		return
	}

	err = c.QueueRepo.DeleteItem(repo.DeleteEmbeddingsQueue, qItem.Item)
	if err != nil {
		ctxLogger.WithError(err).Error("Failed to remove item from the queue")
		return
	}

	ctxLogger.Info("Successfully deleted all embeddings")
}

func (c *Controller) getObjectKey(userID int64, fileID int64, model string) string {
	return c.getEmbeddingObjectPrefix(userID, fileID) + model + ".json"
}

func (c *Controller) getEmbeddingObjectPrefix(userID int64, fileID int64) string {
	return strconv.FormatInt(userID, 10) + "/ml-data/" + strconv.FormatInt(fileID, 10) + "/"
}

// uploadObject uploads the embedding object to the object store and returns the object size
func (c *Controller) uploadObject(obj ente.EmbeddingObject, key string) (int, error) {
	embeddingObj, _ := json.Marshal(obj)
	uploader := s3manager.NewUploaderWithClient(c.S3Config.GetHotS3Client())
	up := s3manager.UploadInput{
		Bucket: c.S3Config.GetHotBucket(),
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

var globalDiffFetchSemaphore = make(chan struct{}, 300)

var globalFileFetchSemaphore = make(chan struct{}, 400)

func (c *Controller) getEmbeddingObjectsParallel(objectKeys []string) ([]ente.EmbeddingObject, error) {
	var wg sync.WaitGroup
	var errs []error
	embeddingObjects := make([]ente.EmbeddingObject, len(objectKeys))
	downloader := s3manager.NewDownloaderWithClient(c.S3Config.GetHotS3Client())

	for i, objectKey := range objectKeys {
		wg.Add(1)
		globalDiffFetchSemaphore <- struct{}{} // Acquire from global semaphore
		go func(i int, objectKey string) {
			defer wg.Done()
			defer func() { <-globalDiffFetchSemaphore }() // Release back to global semaphore

			obj, err := c.getEmbeddingObject(objectKey, downloader)
			if err != nil {
				errs = append(errs, err)
				log.Error("error fetching embedding object: "+objectKey, err)
			} else {
				embeddingObjects[i] = obj
			}
		}(i, objectKey)
	}

	wg.Wait()

	if len(errs) > 0 {
		return nil, stacktrace.Propagate(errors.New("failed to fetch some objects"), "")
	}

	return embeddingObjects, nil
}

type embeddingObjectResult struct {
	embeddingObject ente.EmbeddingObject
	dbEmbeddingRow  ente.Embedding
	err             error
}

func (c *Controller) getEmbeddingObjectsParallelV2(userID int64, dbEmbeddingRows []ente.Embedding) ([]embeddingObjectResult, error) {
	var wg sync.WaitGroup
	embeddingObjects := make([]embeddingObjectResult, len(dbEmbeddingRows))
	downloader := s3manager.NewDownloaderWithClient(c.S3Config.GetHotS3Client())

	for i, dbEmbeddingRow := range dbEmbeddingRows {
		wg.Add(1)
		globalFileFetchSemaphore <- struct{}{} // Acquire from global semaphore
		go func(i int, dbEmbeddingRow ente.Embedding) {
			defer wg.Done()
			defer func() { <-globalFileFetchSemaphore }() // Release back to global semaphore
			objectKey := c.getObjectKey(userID, dbEmbeddingRow.FileID, dbEmbeddingRow.Model)
			obj, err := c.getEmbeddingObject(objectKey, downloader)
			if err != nil {
				log.Error("error fetching embedding object: "+objectKey, err)
				embeddingObjects[i] = embeddingObjectResult{
					err:            err,
					dbEmbeddingRow: dbEmbeddingRow,
				}

			} else {
				embeddingObjects[i] = embeddingObjectResult{
					embeddingObject: obj,
					dbEmbeddingRow:  dbEmbeddingRow,
				}
			}
		}(i, dbEmbeddingRow)
	}
	wg.Wait()
	return embeddingObjects, nil
}

func (c *Controller) getEmbeddingObject(objectKey string, downloader *s3manager.Downloader) (ente.EmbeddingObject, error) {
	var obj ente.EmbeddingObject
	buff := &aws.WriteAtBuffer{}
	_, err := downloader.Download(buff, &s3.GetObjectInput{
		Bucket: c.S3Config.GetHotBucket(),
		Key:    &objectKey,
	})
	if err != nil {
		log.Error(err)
		return obj, stacktrace.Propagate(err, "")
	}
	err = json.Unmarshal(buff.Bytes(), &obj)
	if err != nil {
		log.Error(err)
		return obj, stacktrace.Propagate(err, "")
	}
	return obj, nil
}

func (c *Controller) _validateGetFileEmbeddingsRequest(ctx *gin.Context, userID int64, req ente.GetFilesEmbeddingRequest) error {
	if req.Model == "" {
		return ente.NewBadRequestWithMessage("model is required")
	}
	if len(req.FileIDs) == 0 {
		return ente.NewBadRequestWithMessage("fileIDs are required")
	}
	if len(req.FileIDs) > 200 {
		return ente.NewBadRequestWithMessage("fileIDs should be less than or equal to 200")
	}
	if err := c.AccessCtrl.VerifyFileOwnership(ctx, &access.VerifyFileOwnershipParams{
		ActorUserId: userID,
		FileIDs:     req.FileIDs,
	}); err != nil {
		return stacktrace.Propagate(err, "User does not own some file(s)")
	}
	return nil
}
