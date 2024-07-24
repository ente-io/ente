package embedding

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/ente-io/museum/pkg/utils/array"
	"strconv"
	"strings"
	"sync"
	gTime "time"

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
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

const (
	// maxEmbeddingDataSize is the min size of an embedding object in bytes
	minEmbeddingDataSize  = 2048
	embeddingFetchTimeout = 10 * gTime.Second
)

// _fetchConfig is the configuration for the fetching objects from S3
type _fetchConfig struct {
	RetryCount     int
	InitialTimeout gTime.Duration
	MaxTimeout     gTime.Duration
}

var _defaultFetchConfig = _fetchConfig{RetryCount: 3, InitialTimeout: 10 * gTime.Second, MaxTimeout: 30 * gTime.Second}
var _b2FetchConfig = _fetchConfig{RetryCount: 3, InitialTimeout: 15 * gTime.Second, MaxTimeout: 30 * gTime.Second}

type Controller struct {
	Repo                     *embedding.Repository
	AccessCtrl               access.Controller
	ObjectCleanupController  *controller.ObjectCleanupController
	S3Config                 *s3config.S3Config
	QueueRepo                *repo.QueueRepository
	TaskLockingRepo          *repo.TaskLockRepository
	FileRepo                 *repo.FileRepository
	CollectionRepo           *repo.CollectionRepository
	HostName                 string
	cleanupCronRunning       bool
	derivedStorageDataCenter string
	downloadManagerCache     map[string]*s3manager.Downloader
}

func New(repo *embedding.Repository, accessCtrl access.Controller, objectCleanupController *controller.ObjectCleanupController, s3Config *s3config.S3Config, queueRepo *repo.QueueRepository, taskLockingRepo *repo.TaskLockRepository, fileRepo *repo.FileRepository, collectionRepo *repo.CollectionRepository, hostName string) *Controller {
	embeddingDcs := []string{s3Config.GetHotBackblazeDC(), s3Config.GetHotWasabiDC(), s3Config.GetWasabiDerivedDC(), s3Config.GetDerivedStorageDataCenter()}
	cache := make(map[string]*s3manager.Downloader, len(embeddingDcs))
	for i := range embeddingDcs {
		s3Client := s3Config.GetS3Client(embeddingDcs[i])
		cache[embeddingDcs[i]] = s3manager.NewDownloaderWithClient(&s3Client)
	}
	return &Controller{
		Repo:                     repo,
		AccessCtrl:               accessCtrl,
		ObjectCleanupController:  objectCleanupController,
		S3Config:                 s3Config,
		QueueRepo:                queueRepo,
		TaskLockingRepo:          taskLockingRepo,
		FileRepo:                 fileRepo,
		CollectionRepo:           collectionRepo,
		HostName:                 hostName,
		derivedStorageDataCenter: s3Config.GetDerivedStorageDataCenter(),
		downloadManagerCache:     cache,
	}
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
		Client:             network.GetClientInfo(ctx),
	}
	size, uploadErr := c.uploadObject(obj, c.getObjectKey(userID, req.FileID, req.Model), c.derivedStorageDataCenter)
	if uploadErr != nil {
		log.Error(uploadErr)
		return nil, stacktrace.Propagate(uploadErr, "")
	}
	embedding, err := c.Repo.InsertOrUpdate(ctx, userID, req, size, version, c.derivedStorageDataCenter)
	embedding.Version = &version
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &embedding, nil
}

func (c *Controller) GetIndexedFiles(ctx *gin.Context, req ente.GetIndexedFiles) ([]ente.IndexedFile, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	updateSince := int64(0)
	if req.SinceTime != nil {
		updateSince = *req.SinceTime
	}
	indexedFiles, err := c.Repo.GetIndexedFiles(ctx, userID, req.Model, updateSince, req.Limit)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return indexedFiles, nil
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
		embeddingObjects, err := c.getEmbeddingObjectsParallel(objectKeys, c.derivedStorageDataCenter)
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

	embeddingsWithData := make([]ente.Embedding, 0)
	noEmbeddingFileIds := make([]int64, 0)
	dbFileIds := make([]int64, 0)
	// fileIDs that were indexed, but they don't contain any embedding information
	for i := range userFileEmbeddings {
		dbFileIds = append(dbFileIds, userFileEmbeddings[i].FileID)
		if userFileEmbeddings[i].Size != nil && *userFileEmbeddings[i].Size < minEmbeddingDataSize {
			noEmbeddingFileIds = append(noEmbeddingFileIds, userFileEmbeddings[i].FileID)
		} else {
			embeddingsWithData = append(embeddingsWithData, userFileEmbeddings[i])
		}
	}
	pendingIndexFileIds := array.FindMissingElementsInSecondList(req.FileIDs, dbFileIds)
	errFileIds := make([]int64, 0)

	// Fetch missing userFileEmbeddings in parallel
	embeddingObjects, err := c.getEmbeddingObjectsParallelV2(userID, embeddingsWithData, c.derivedStorageDataCenter)
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
		Embeddings:          fetchedEmbeddings,
		PendingIndexFileIDs: pendingIndexFileIds,
		ErrFileIDs:          errFileIds,
		NoEmbeddingFileIDs:  noEmbeddingFileIds,
	}, nil
}

func (c *Controller) getObjectKey(userID int64, fileID int64, model string) string {
	return c.getEmbeddingObjectPrefix(userID, fileID) + model + ".json"
}

func (c *Controller) getEmbeddingObjectPrefix(userID int64, fileID int64) string {
	return strconv.FormatInt(userID, 10) + "/ml-data/" + strconv.FormatInt(fileID, 10) + "/"
}

// Get userId, model and fileID from the object key
func (c *Controller) getEmbeddingObjectDetails(objectKey string) (userID int64, model string, fileID int64) {
	split := strings.Split(objectKey, "/")
	userID, _ = strconv.ParseInt(split[0], 10, 64)
	fileID, _ = strconv.ParseInt(split[2], 10, 64)
	model = strings.Split(split[3], ".")[0]
	return userID, model, fileID
}

// uploadObject uploads the embedding object to the object store and returns the object size
func (c *Controller) uploadObject(obj ente.EmbeddingObject, key string, dc string) (int, error) {
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

var globalDiffFetchSemaphore = make(chan struct{}, 300)

var globalFileFetchSemaphore = make(chan struct{}, 400)

func (c *Controller) getEmbeddingObjectsParallel(objectKeys []string, dc string) ([]ente.EmbeddingObject, error) {
	var wg sync.WaitGroup
	var errs []error
	embeddingObjects := make([]ente.EmbeddingObject, len(objectKeys))
	for i, objectKey := range objectKeys {
		wg.Add(1)
		globalDiffFetchSemaphore <- struct{}{} // Acquire from global semaphore
		go func(i int, objectKey string) {
			defer wg.Done()
			defer func() { <-globalDiffFetchSemaphore }() // Release back to global semaphore

			obj, err := c.getEmbeddingObject(context.Background(), objectKey, dc)
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

func (c *Controller) getEmbeddingObjectsParallelV2(userID int64, dbEmbeddingRows []ente.Embedding, dc string) ([]embeddingObjectResult, error) {
	var wg sync.WaitGroup
	embeddingObjects := make([]embeddingObjectResult, len(dbEmbeddingRows))

	for i, dbEmbeddingRow := range dbEmbeddingRows {
		wg.Add(1)
		globalFileFetchSemaphore <- struct{}{} // Acquire from global semaphore
		go func(i int, dbEmbeddingRow ente.Embedding) {
			defer wg.Done()
			defer func() { <-globalFileFetchSemaphore }() // Release back to global semaphore
			objectKey := c.getObjectKey(userID, dbEmbeddingRow.FileID, dbEmbeddingRow.Model)
			obj, err := c.getEmbeddingObject(context.Background(), objectKey, dc)
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

func (c *Controller) getEmbeddingObject(ctx context.Context, objectKey string, dc string) (ente.EmbeddingObject, error) {
	opt := _defaultFetchConfig
	if dc == c.S3Config.GetHotBackblazeDC() {
		opt = _b2FetchConfig
	}
	ctxLogger := log.WithField("objectKey", objectKey).WithField("dc", dc)
	totalAttempts := opt.RetryCount + 1
	timeout := opt.InitialTimeout
	for i := 0; i < totalAttempts; i++ {
		if i > 0 {
			timeout = timeout * 2
			if timeout > opt.MaxTimeout {
				timeout = opt.MaxTimeout
			}
		}
		fetchCtx, cancel := context.WithTimeout(ctx, timeout)
		select {
		case <-ctx.Done():
			cancel()
			return ente.EmbeddingObject{}, stacktrace.Propagate(ctx.Err(), "")
		default:
			obj, err := c.downloadObject(fetchCtx, objectKey, dc)
			cancel() // Ensure cancel is called to release resources
			if err == nil {
				if i > 0 {
					ctxLogger.Infof("Fetched object after %d attempts", i)
				}
				return obj, nil
			}
			// Check if the error is due to context timeout or cancellation
			if err == nil && fetchCtx.Err() != nil {
				ctxLogger.Error("Fetch timed out or cancelled: ", fetchCtx.Err())
			} else {
				// check if the error is due to object not found
				if s3Err, ok := err.(awserr.RequestFailure); ok {
					if s3Err.Code() == s3.ErrCodeNoSuchKey {
						var srcDc, destDc string
						destDc = c.S3Config.GetDerivedStorageDataCenter()
						// todo:(neeraj) Refactor this later to get available the DC from the DB instead of
						// querying the DB. This will help in case of multiple DCs and avoid querying the DB
						// for each object.
						// For initial migration, as we know that original DC was b2, and if the embedding is not found
						// in the new derived DC, we can try to fetch it from the B2 DC.
						if c.derivedStorageDataCenter != c.S3Config.GetHotBackblazeDC() {
							// embeddings ideally should ideally be in the default hot bucket b2
							srcDc = c.S3Config.GetHotBackblazeDC()
						} else {
							_, modelName, fileID := c.getEmbeddingObjectDetails(objectKey)
							activeDcs, err := c.Repo.GetOtherDCsForFileAndModel(context.Background(), fileID, modelName, c.derivedStorageDataCenter)
							if err != nil {
								return ente.EmbeddingObject{}, stacktrace.Propagate(err, "failed to get other dc")
							}
							if len(activeDcs) > 0 {
								srcDc = activeDcs[0]
							} else {
								ctxLogger.Error("Object not found in any dc ", s3Err)
								return ente.EmbeddingObject{}, stacktrace.Propagate(errors.New("object not found"), "")
							}
						}
						copyEmbeddingObject, err := c.copyEmbeddingObject(ctx, objectKey, srcDc, destDc)
						if err == nil {
							ctxLogger.Infof("Got object from dc %s", srcDc)
							return *copyEmbeddingObject, nil
						} else {
							ctxLogger.WithError(err).Errorf("Failed to get object from fallback dc %s", srcDc)
						}
						return ente.EmbeddingObject{}, stacktrace.Propagate(errors.New("object not found"), "")
					}
				}
				ctxLogger.Error("Failed to fetch object: ", err)
			}
		}
	}
	return ente.EmbeddingObject{}, stacktrace.Propagate(errors.New("failed to fetch object"), "")
}

func (c *Controller) downloadObject(ctx context.Context, objectKey string, dc string) (ente.EmbeddingObject, error) {
	var obj ente.EmbeddingObject
	buff := &aws.WriteAtBuffer{}
	bucket := c.S3Config.GetBucket(dc)
	downloader := c.downloadManagerCache[dc]
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

// download the embedding object from hot bucket and upload to embeddings bucket
func (c *Controller) copyEmbeddingObject(ctx context.Context, objectKey string, srcDC, destDC string) (*ente.EmbeddingObject, error) {
	if srcDC == destDC {
		return nil, stacktrace.Propagate(errors.New("src and dest dc can not be same"), "")
	}
	obj, err := c.downloadObject(ctx, objectKey, srcDC)
	if err != nil {
		return nil, stacktrace.Propagate(err, fmt.Sprintf("failed to download object from %s", srcDC))
	}
	go func() {
		userID, modelName, fileID := c.getEmbeddingObjectDetails(objectKey)
		size, uploadErr := c.uploadObject(obj, objectKey, c.derivedStorageDataCenter)
		if uploadErr != nil {
			log.WithField("object", objectKey).Error("Failed to copy  to embeddings bucket: ", uploadErr)
		}
		updateDcErr := c.Repo.AddNewDC(context.Background(), fileID, ente.Model(modelName), userID, size, destDC)
		if updateDcErr != nil {
			log.WithField("object", objectKey).Error("Failed to update dc in db: ", updateDcErr)
			return
		}
	}()
	return &obj, nil
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
