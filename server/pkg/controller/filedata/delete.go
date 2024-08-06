package filedata

import (
	"context"
	"fmt"
	"github.com/ente-io/museum/ente/filedata"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/time"
	log "github.com/sirupsen/logrus"
	"strconv"
)

// CleanUpDeletedFileData clears associated file data from the object store
func (c *Controller) CleanUpDeletedFileData() {
	log.Info("Cleaning up deleted file data")
	if c.cleanupCronRunning {
		log.Info("Skipping CleanUpDeletedFileData cron run as another instance is still running")
		return
	}
	c.cleanupCronRunning = true
	defer func() {
		c.cleanupCronRunning = false
	}()
	items, err := c.QueueRepo.GetItemsReadyForDeletion(repo.DeleteFileDataQueue, 200)
	if err != nil {
		log.WithError(err).Error("Failed to fetch items from queue")
		return
	}
	for _, i := range items {
		c.deleteFileData(i)
	}
}

func (c *Controller) deleteFileData(qItem repo.QueueItem) {
	lockName := fmt.Sprintf("FileDataDelete:%s", qItem.Item)
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
	ctxLogger.Debug("Deleting all file data")
	fileID, _ := strconv.ParseInt(qItem.Item, 10, 64)
	ownerID, err := c.FileRepo.GetOwnerID(fileID)
	if err != nil {
		ctxLogger.WithError(err).Error("Failed to fetch ownerID")
		return
	}
	rows, err := c.Repo.GetFileData(context.Background(), fileID)
	if err != nil {
		ctxLogger.WithError(err).Error("Failed to fetch datacenters")
		return
	}
	for i := range rows {
		fileDataRow := rows[i]
		objectKeys := filedata.AllObjects(fileID, ownerID, fileDataRow.Type)
		// Delete from delete/stale buckets
		for j := range fileDataRow.DeleteFromBuckets {
			bucketID := fileDataRow.DeleteFromBuckets[j]
			for k := range objectKeys {
				err = c.ObjectCleanupController.DeleteObjectFromDataCenter(objectKeys[k], bucketID)
				if err != nil {
					ctxLogger.WithError(err).Error("Failed to delete object from datacenter")
					return
				}
			}
			dbErr := c.Repo.RemoveBucketFromDeletedBuckets(fileDataRow, bucketID)
			if dbErr != nil {
				ctxLogger.WithError(dbErr).Error("Failed to remove from db")
				return
			}
		}
		// Delete from replicated buckets
		for j := range fileDataRow.ReplicatedBuckets {
			bucketID := fileDataRow.ReplicatedBuckets[j]
			for k := range objectKeys {
				err = c.ObjectCleanupController.DeleteObjectFromDataCenter(objectKeys[k], bucketID)
				if err != nil {
					ctxLogger.WithError(err).Error("Failed to delete object from datacenter")
					return
				}
			}
			dbErr := c.Repo.RemoveBucketFromReplicatedBuckets(fileDataRow, bucketID)
			if dbErr != nil {
				ctxLogger.WithError(dbErr).Error("Failed to remove from db")
				return
			}
		}
		// Delete from Latest bucket
		for k := range objectKeys {
			err = c.ObjectCleanupController.DeleteObjectFromDataCenter(objectKeys[k], fileDataRow.LatestBucket)
			if err != nil {
				ctxLogger.WithError(err).Error("Failed to delete object from datacenter")
				return
			}
		}
		dbErr := c.Repo.DeleteFileData(context.Background(), fileDataRow.FileID, fileDataRow.Type, fileDataRow.LatestBucket)
		if dbErr != nil {
			ctxLogger.WithError(dbErr).Error("Failed to remove from db")
			return
		}
	}
	if err != nil {
		ctxLogger.WithError(err).Error("Failed delete data")
		return
	}
	err = c.QueueRepo.DeleteItem(repo.DeleteFileDataQueue, qItem.Item)
	if err != nil {
		ctxLogger.WithError(err).Error("Failed to remove item from the queue")
		return
	}
	ctxLogger.Info("Successfully deleted all file data")
}
