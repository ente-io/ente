package filedata

import (
	"context"
	"fmt"
	"github.com/ente-io/museum/ente/filedata"
	fileDataRepo "github.com/ente-io/museum/pkg/repo/filedata"
	"github.com/sirupsen/logrus"
	log "github.com/sirupsen/logrus"
)

// StartDataDeletion clears associated file data from the object store
func (c *Controller) StartDataDeletion() {
	log.Info("Cleaning up deleted file data")
	// todo: start goroutine workers to delete data

}

func (c *Controller) DeleteFileData(fileID int64) error {
	ownerID, err := c.FileRepo.GetOwnerID(fileID)
	if err != nil {
		return err
	}
	rows, err := c.Repo.GetFileData(context.Background(), fileID)
	if err != nil {
		return err
	}
	for i := range rows {
		fileDataRow := rows[i]
		ctxLogger := log.WithField("file_id", fileDataRow.DeleteFromBuckets).WithField("type", fileDataRow.Type).WithField("user_id", fileDataRow.UserID)
		objectKeys := filedata.AllObjects(fileID, ownerID, fileDataRow.Type)
		bucketColumnMap := make(map[string]string)
		bucketColumnMap, err = getMapOfbucketItToColumn(fileDataRow)
		if err != nil {
			ctxLogger.WithError(err).Error("Failed to get bucketColumnMap")
			return err
		}
		// Delete objects and remove buckets
		for bucketID, columnName := range bucketColumnMap {
			for _, objectKey := range objectKeys {
				err := c.ObjectCleanupController.DeleteObjectFromDataCenter(objectKey, bucketID)
				if err != nil {
					ctxLogger.WithError(err).WithFields(logrus.Fields{
						"bucketID":  bucketID,
						"column":    columnName,
						"objectKey": objectKey,
					}).Error("Failed to delete object from datacenter")
					return err
				}
			}
			dbErr := c.Repo.RemoveBucket(fileDataRow, bucketID, columnName)
			if dbErr != nil {
				ctxLogger.WithError(dbErr).WithFields(logrus.Fields{
					"bucketID": bucketID,
					"column":   columnName,
				}).Error("Failed to remove bucket from db")
				return dbErr

			}
		}
		// Delete from Latest bucket
		for k := range objectKeys {
			err = c.ObjectCleanupController.DeleteObjectFromDataCenter(objectKeys[k], fileDataRow.LatestBucket)
			if err != nil {
				ctxLogger.WithError(err).Error("Failed to delete object from datacenter")
				return err
			}
		}
		dbErr := c.Repo.DeleteFileData(context.Background(), fileDataRow)
		if dbErr != nil {
			ctxLogger.WithError(dbErr).Error("Failed to remove from db")
			return err
		}
	}
	return nil
}

func getMapOfbucketItToColumn(row filedata.Row) (map[string]string, error) {
	bucketColumnMap := make(map[string]string)
	for _, bucketID := range row.DeleteFromBuckets {
		if existingColumn, exists := bucketColumnMap[bucketID]; exists {
			return nil, fmt.Errorf("Duplicate DeleteFromBuckets ID found: %s in column %s", bucketID, existingColumn)
		}
		bucketColumnMap[bucketID] = fileDataRepo.DeletionColumn
	}
	for _, bucketID := range row.ReplicatedBuckets {
		if existingColumn, exists := bucketColumnMap[bucketID]; exists {
			return nil, fmt.Errorf("Duplicate ReplicatedBuckets ID found: %s in column %s", bucketID, existingColumn)
		}
		bucketColumnMap[bucketID] = fileDataRepo.ReplicationColumn
	}
	for _, bucketID := range row.InflightReplicas {
		if existingColumn, exists := bucketColumnMap[bucketID]; exists {
			return nil, fmt.Errorf("Duplicate InFlightBucketID found: %s in column %s", bucketID, existingColumn)
		}
		bucketColumnMap[bucketID] = fileDataRepo.InflightRepColumn
	}
	return bucketColumnMap, nil
}
