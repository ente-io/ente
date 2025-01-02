package access

import (
	"github.com/ente-io/museum/ente"
	enteArray "github.com/ente-io/museum/pkg/utils/array"
	"github.com/ente-io/stacktrace"
	"github.com/gin-contrib/requestid"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

type VerifyFileOwnershipParams struct {
	// userID of the user trying to fetch the controller
	ActorUserId int64
	FileIDs     []int64
}

type CanAccessFileParams struct {
	ActorUserID int64
	FileIDs     []int64
}

// VerifyFileOwnership will return error if given fileIDs are not valid or don't belong to the ownerID
func (c controllerImpl) VerifyFileOwnership(ctx *gin.Context, req *VerifyFileOwnershipParams) error {
	if enteArray.ContainsDuplicateInInt64Array(req.FileIDs) {
		return stacktrace.Propagate(ente.ErrBadRequest, "duplicate fileIDs")
	}
	ownerID := req.ActorUserId
	logger := log.WithFields(log.Fields{
		"req_id": requestid.Get(ctx),
	})
	return c.FileRepo.VerifyFileOwner(ctx, req.FileIDs, ownerID, logger)
}

func (c controllerImpl) CanAccessFile(ctx *gin.Context, req *CanAccessFileParams) error {
	if enteArray.ContainsDuplicateInInt64Array(req.FileIDs) {
		return stacktrace.Propagate(ente.ErrBadRequest, "duplicate fileIDs")
	}
	ownerToFilesMap, err := c.FileRepo.GetOwnerToFileIDsMap(ctx, req.FileIDs)
	if err != nil {
		return stacktrace.Propagate(err, "failed to get owner to fileIDs map")
	}
	// iterate over the map and check if the ownerID has access to the fileIDs
	for owner, fileIDs := range ownerToFilesMap {
		if owner == req.ActorUserID {
			continue
		}
		cIDs, collErr := c.CollectionRepo.GetCollectionIDsSharedWithUser(req.ActorUserID)
		if collErr != nil {
			return stacktrace.Propagate(collErr, "")
		}
		cwIDS, collErr := c.CollectionRepo.GetCollectionIDsSharedWithUser(owner)
		if collErr != nil {
			return stacktrace.Propagate(collErr, "")
		}
		cIDs = append(cIDs, cwIDS...)
		accessErr := c.CollectionRepo.DoAllFilesExistInGivenCollections(fileIDs, cIDs)
		if accessErr != nil {
			log.WithFields(log.Fields{
				"req_id": requestid.Get(ctx),
			}).WithError(accessErr).Error("access check failed")
			return stacktrace.Propagate(ente.ErrPermissionDenied, "access denied")
		}
	}
	return nil
}
