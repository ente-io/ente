package controller

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// CreateMetaFile adds an entry for a file in the respective tables
func (c *FileController) CreateMetaFile(ctx *gin.Context, userID int64, file ente.MetaFile, userAgent string, app ente.App) (*ente.File, error) {
	collection, collErr := c.CollectionRepo.Get(file.CollectionID)
	if collErr != nil {
		return nil, stacktrace.Propagate(collErr, "")
	}
	// Verify that user owns the collection.
	// Warning: Do not remove this check
	if collection.Owner.ID != userID {
		return nil, stacktrace.Propagate(ente.ErrPermissionDenied, "collection doesn't belong to user")
	}
	if collection.IsDeleted {
		return nil, stacktrace.Propagate(ente.ErrCollectionDeleted, "collection has been deleted")
	}
	if file.OwnerID != userID {
		return nil, stacktrace.Propagate(ente.ErrPermissionDenied, "file ownerID doesn't match with userID")
	}
	resp, err := c.FileRepo.CreateMetaFile(file, userID, app)
	return resp, stacktrace.Propagate(err, "failed to create meta file")
}
