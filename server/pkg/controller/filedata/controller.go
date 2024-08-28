package filedata

import (
	"context"
	"errors"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/ente-io/museum/ente"
	fileData "github.com/ente-io/museum/ente/filedata"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/controller/access"
	"github.com/ente-io/museum/pkg/repo"
	fileDataRepo "github.com/ente-io/museum/pkg/repo/filedata"
	"github.com/ente-io/museum/pkg/utils/array"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/network"
	"github.com/ente-io/museum/pkg/utils/s3config"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
	"strings"
	"sync"
	gTime "time"
)

// _fetchConfig is the configuration for the fetching objects from S3
type _fetchConfig struct {
	RetryCount     int
	InitialTimeout gTime.Duration
	MaxTimeout     gTime.Duration
}

var _defaultFetchConfig = _fetchConfig{RetryCount: 3, InitialTimeout: 10 * gTime.Second, MaxTimeout: 30 * gTime.Second}
var globalFileFetchSemaphore = make(chan struct{}, 400)

type bulkS3MetaFetchResult struct {
	s3MetaObject fileData.S3FileMetadata
	dbEntry      fileData.Row
	err          error
}

type Controller struct {
	Repo                    *fileDataRepo.Repository
	AccessCtrl              access.Controller
	ObjectCleanupController *controller.ObjectCleanupController
	S3Config                *s3config.S3Config
	FileRepo                *repo.FileRepository
	CollectionRepo          *repo.CollectionRepository
	downloadManagerCache    map[string]*s3manager.Downloader
	// for downloading objects from s3 for replication
	workerURL string
}

func New(repo *fileDataRepo.Repository,
	accessCtrl access.Controller,
	objectCleanupController *controller.ObjectCleanupController,
	s3Config *s3config.S3Config,
	fileRepo *repo.FileRepository,
	collectionRepo *repo.CollectionRepository) *Controller {
	embeddingDcs := []string{s3Config.GetHotBackblazeDC(), s3Config.GetHotWasabiDC(), s3Config.GetWasabiDerivedDC(), s3Config.GetDerivedStorageDataCenter(), "b5"}
	cache := make(map[string]*s3manager.Downloader, len(embeddingDcs))
	for i := range embeddingDcs {
		s3Client := s3Config.GetS3Client(embeddingDcs[i])
		cache[embeddingDcs[i]] = s3manager.NewDownloaderWithClient(&s3Client)
	}
	return &Controller{
		Repo:                    repo,
		AccessCtrl:              accessCtrl,
		ObjectCleanupController: objectCleanupController,
		S3Config:                s3Config,
		FileRepo:                fileRepo,
		CollectionRepo:          collectionRepo,
		downloadManagerCache:    cache,
	}
}

func (c *Controller) InsertOrUpdate(ctx *gin.Context, req *fileData.PutFileDataRequest) error {
	if err := req.Validate(); err != nil {
		return stacktrace.Propagate(err, "validation failed")
	}
	userID := auth.GetUserID(ctx.Request.Header)
	err := c._validatePermission(ctx, req.FileID, userID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if req.Type != ente.MlData && req.Type != ente.PreviewVideo {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage("unsupported object type "+string(req.Type)), "")
	}
	fileOwnerID := userID
	bucketID := c.S3Config.GetBucketID(req.Type)
	if req.Type == ente.PreviewVideo {
		fileObjectKey := req.S3FileObjectKey(fileOwnerID)
		if !strings.Contains(*req.ObjectKey, fileObjectKey) {
			return stacktrace.Propagate(ente.NewBadRequestWithMessage("objectKey should contain the file object key"), "")
		}
		err = c.copyObject(*req.ObjectKey, fileObjectKey, bucketID)
		if err != nil {
			return err
		}
	}
	objectKey := req.S3FileMetadataObjectKey(fileOwnerID)
	obj := fileData.S3FileMetadata{
		Version:          *req.Version,
		EncryptedData:    *req.EncryptedData,
		DecryptionHeader: *req.DecryptionHeader,
		Client:           network.GetClientInfo(ctx),
	}
	// Start a goroutine to handle the upload and insert operations
	go func() {
		logger := log.WithField("objectKey", objectKey).WithField("fileID", req.FileID).WithField("type", req.Type)
		size, uploadErr := c.uploadObject(obj, objectKey, bucketID)
		if uploadErr != nil {
			logger.WithError(uploadErr).Error("upload failed")
			return
		}

		row := fileData.Row{
			FileID:       req.FileID,
			Type:         req.Type,
			UserID:       fileOwnerID,
			Size:         size,
			LatestBucket: bucketID,
		}
		dbInsertErr := c.Repo.InsertOrUpdate(context.Background(), row)
		if dbInsertErr != nil {
			logger.WithError(dbInsertErr).Error("insert or update failed")
			return
		}
	}()
	return nil
}

func (c *Controller) GetFileData(ctx *gin.Context, req fileData.GetFileData) (*fileData.Entity, error) {
	if err := req.Validate(); err != nil {
		return nil, stacktrace.Propagate(err, "validation failed")
	}
	if err := c._validatePermission(ctx, req.FileID, auth.GetUserID(ctx.Request.Header)); err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	doRows, err := c.Repo.GetFilesData(ctx, req.Type, []int64{req.FileID})
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if len(doRows) == 0 || doRows[0].IsDeleted {
		return nil, stacktrace.Propagate(ente.ErrNotFound, "")
	}
	s3MetaObject, err := c.fetchS3FileMetadata(context.Background(), doRows[0], doRows[0].LatestBucket)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &fileData.Entity{
		FileID:           doRows[0].FileID,
		Type:             doRows[0].Type,
		EncryptedData:    s3MetaObject.EncryptedData,
		DecryptionHeader: s3MetaObject.DecryptionHeader,
	}, nil
}

func (c *Controller) GetFilesData(ctx *gin.Context, req fileData.GetFilesData) (*fileData.GetFilesDataResponse, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	if err := c._validateGetFilesData(ctx, userID, req); err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	doRows, err := c.Repo.GetFilesData(ctx, req.Type, req.FileIDs)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	activeRows := make([]fileData.Row, 0)
	dbFileIds := make([]int64, 0)
	errFileIds := make([]int64, 0)
	for i := range doRows {
		dbFileIds = append(dbFileIds, doRows[i].FileID)
		if !doRows[i].IsDeleted {
			activeRows = append(activeRows, doRows[i])
		}
	}
	pendingIndexFileIds := array.FindMissingElementsInSecondList(req.FileIDs, dbFileIds)
	// Fetch missing doRows in parallel
	s3MetaFetchResults, err := c.getS3FileMetadataParallel(activeRows)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	fetchedEmbeddings := make([]fileData.Entity, 0)

	// Populate missing data in doRows from fetched objects
	for _, obj := range s3MetaFetchResults {
		if obj.err != nil {
			errFileIds = append(errFileIds, obj.dbEntry.FileID)
		} else {
			fetchedEmbeddings = append(fetchedEmbeddings, fileData.Entity{
				FileID:           obj.dbEntry.FileID,
				Type:             obj.dbEntry.Type,
				EncryptedData:    obj.s3MetaObject.EncryptedData,
				DecryptionHeader: obj.s3MetaObject.DecryptionHeader,
			})
		}
	}

	return &fileData.GetFilesDataResponse{
		Data:                fetchedEmbeddings,
		PendingIndexFileIDs: pendingIndexFileIds,
		ErrFileIDs:          errFileIds,
	}, nil
}

func (c *Controller) getS3FileMetadataParallel(dbRows []fileData.Row) ([]bulkS3MetaFetchResult, error) {
	var wg sync.WaitGroup
	embeddingObjects := make([]bulkS3MetaFetchResult, len(dbRows))
	for i := range dbRows {
		dbRow := dbRows[i]
		wg.Add(1)
		globalFileFetchSemaphore <- struct{}{} // Acquire from global semaphore
		go func(i int, row fileData.Row) {
			defer wg.Done()
			defer func() { <-globalFileFetchSemaphore }() // Release back to global semaphore
			dc := row.LatestBucket
			s3FileMetadata, err := c.fetchS3FileMetadata(context.Background(), row, dc)
			if err != nil {
				log.WithField("bucket", dc).
					Error("error fetching  object: "+row.S3FileMetadataObjectKey(), err)
				embeddingObjects[i] = bulkS3MetaFetchResult{
					err:     err,
					dbEntry: row,
				}

			} else {
				embeddingObjects[i] = bulkS3MetaFetchResult{
					s3MetaObject: *s3FileMetadata,
					dbEntry:      dbRow,
				}
			}
		}(i, dbRow)
	}
	wg.Wait()
	return embeddingObjects, nil
}

func (c *Controller) fetchS3FileMetadata(ctx context.Context, row fileData.Row, dc string) (*fileData.S3FileMetadata, error) {
	opt := _defaultFetchConfig
	objectKey := row.S3FileMetadataObjectKey()
	ctxLogger := log.WithField("objectKey", objectKey).WithField("dc", row.LatestBucket)
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
			return nil, stacktrace.Propagate(ctx.Err(), "")
		default:
			obj, err := c.downloadObject(fetchCtx, objectKey, dc)
			cancel() // Ensure cancel is called to release resources
			if err == nil {
				if i > 0 {
					ctxLogger.Infof("Fetched object after %d attempts", i)
				}
				return &obj, nil
			}
			// Check if the error is due to context timeout or cancellation
			if err == nil && fetchCtx.Err() != nil {
				ctxLogger.Error("Fetch timed out or cancelled: ", fetchCtx.Err())
			} else {
				// check if the error is due to object not found
				if s3Err, ok := err.(awserr.RequestFailure); ok {
					if s3Err.Code() == s3.ErrCodeNoSuchKey {
						return nil, stacktrace.Propagate(errors.New("object not found"), "")
					}
				}
				ctxLogger.Error("Failed to fetch object: ", err)
			}
		}
	}
	return nil, stacktrace.Propagate(errors.New("failed to fetch object"), "")
}

func (c *Controller) _validateGetFilesData(ctx *gin.Context, userID int64, req fileData.GetFilesData) error {
	if err := req.Validate(); err != nil {
		return stacktrace.Propagate(err, "validation failed")
	}
	if err := c.AccessCtrl.VerifyFileOwnership(ctx, &access.VerifyFileOwnershipParams{
		ActorUserId: userID,
		FileIDs:     req.FileIDs,
	}); err != nil {
		return stacktrace.Propagate(err, "User does not own some file(s)")
	}

	return nil
}

func (c *Controller) _validatePermission(ctx *gin.Context, fileID int64, actorID int64) error {
	err := c.AccessCtrl.VerifyFileOwnership(ctx, &access.VerifyFileOwnershipParams{
		ActorUserId: actorID,
		FileIDs:     []int64{fileID},
	})
	if err != nil {
		return stacktrace.Propagate(err, "User does not own file")
	}
	count, err := c.CollectionRepo.GetCollectionCount(fileID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if count < 1 {
		return stacktrace.Propagate(ente.ErrNotFound, "")
	}
	return nil
}
