package embedding

import (
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
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

	obj := ente.EmbeddingObject{
		Version:            1,
		EncryptedEmbedding: req.EncryptedEmbedding,
		DecryptionHeader:   req.DecryptionHeader,
		Client:             network.GetPrettyUA(ctx.GetHeader("User-Agent")) + "/" + ctx.GetHeader("X-Client-Version"),
	}
	err = c.uploadObject(obj, c.getObjectKey(userID, req.FileID, req.Model))
	if err != nil {
		log.Error(err)
		return nil, stacktrace.Propagate(err, "")
	}
	embedding, err := c.Repo.InsertOrUpdate(ctx, userID, req)
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

func (c *Controller) uploadObject(obj ente.EmbeddingObject, key string) error {
	embeddingObj, _ := json.Marshal(obj)
	uploader := s3manager.NewUploaderWithClient(c.S3Config.GetHotS3Client())
	up := s3manager.UploadInput{
		Bucket: c.S3Config.GetHotBucket(),
		Key:    &key,
		Body:   strings.NewReader(string(embeddingObj)),
	}
	result, err := uploader.Upload(&up)
	if err != nil {
		log.Error(err)
		return stacktrace.Propagate(err, "")
	}
	log.Infof("Uploaded to bucket %s", result.Location)
	return nil
}

var globalFetchSemaphore = make(chan struct{}, 300)

func (c *Controller) getEmbeddingObjectsParallel(objectKeys []string) ([]ente.EmbeddingObject, error) {
	var wg sync.WaitGroup
	var errs []error
	embeddingObjects := make([]ente.EmbeddingObject, len(objectKeys))
	downloader := s3manager.NewDownloaderWithClient(c.S3Config.GetHotS3Client())

	for i, objectKey := range objectKeys {
		wg.Add(1)
		globalFetchSemaphore <- struct{}{} // Acquire from global semaphore
		go func(i int, objectKey string) {
			defer wg.Done()
			defer func() { <-globalFetchSemaphore }() // Release back to global semaphore

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
