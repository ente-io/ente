package embedding

import (
	"context"
	"fmt"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
	"strconv"
)

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
	datacenters, err := c.Repo.GetDatacenters(context.Background(), fileID)
	if err != nil {
		ctxLogger.WithError(err).Error("Failed to fetch datacenters")
		return
	}
	// Ensure that the object are deleted from active derived storage dc. Ideally, this section should never be executed
	// unless there's a bug in storing the DC or the service restarts before removing the rows from the table
	// todo:(neeraj): remove this section after a few weeks of deployment
	if len(datacenters) == 0 {
		ctxLogger.Warn("No datacenters found for file, ensuring deletion from derived storage  and hot DC")
		err = c.ObjectCleanupController.DeleteAllObjectsWithPrefix(prefix, c.S3Config.GetDerivedStorageDataCenter())
		if err != nil {
			ctxLogger.WithError(err).Error("Failed to delete all objects")
			return
		}
		// if Derived DC is different from hot DC, delete from hot DC as well
		if c.derivedStorageDataCenter != c.S3Config.GetHotDataCenter() {
			err = c.ObjectCleanupController.DeleteAllObjectsWithPrefix(prefix, c.S3Config.GetHotDataCenter())
			if err != nil {
				ctxLogger.WithError(err).Error("Failed to delete all objects from hot DC")
				return
			}
		}
	} else {
		ctxLogger.Infof("Deleting from all datacenters %v", datacenters)
	}

	for i := range datacenters {
		err = c.ObjectCleanupController.DeleteAllObjectsWithPrefix(prefix, datacenters[i])
		if err != nil {
			ctxLogger.WithError(err).Errorf("Failed to delete all objects from %s", datacenters[i])
			return
		} else {
			removeErr := c.Repo.RemoveDatacenter(context.Background(), fileID, datacenters[i])
			if removeErr != nil {
				ctxLogger.WithError(removeErr).Error("Failed to remove datacenter from db")
				return
			}
		}
	}

	noDcs, noDcErr := c.Repo.GetDatacenters(context.Background(), fileID)
	if len(noDcs) > 0 || noDcErr != nil {
		ctxLogger.Errorf("Failed to delete from all datacenters %s", noDcs)
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
