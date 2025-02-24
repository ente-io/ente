package embedding

import (
	"strconv"
	gTime "time"

	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/controller/access"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/repo/embedding"
	"github.com/ente-io/museum/pkg/utils/s3config"
)

const (
	// maxEmbeddingDataSize is the min size of an embedding object in bytes
	minEmbeddingDataSize  = 2048
	embeddingFetchTimeout = 10 * gTime.Second
)

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

func (c *Controller) getEmbeddingObjectPrefix(userID int64, fileID int64) string {
	return strconv.FormatInt(userID, 10) + "/ml-data/" + strconv.FormatInt(fileID, 10) + "/"
}
