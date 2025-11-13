package collections

import (
	"fmt"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/access"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

// AddFiles adds files to a collection
func (c *CollectionController) AddFiles(ctx *gin.Context, userID int64, files []ente.CollectionFileItem, cID int64) error {

	resp, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID:   cID,
		ActorUserID:    userID,
		IncludeDeleted: false,
	})
	if err != nil {
		return stacktrace.Propagate(err, "failed to verify collection access")
	}
	if !resp.Role.CanAdd() {
		return stacktrace.Propagate(ente.ErrPermissionDenied, fmt.Sprintf("user %d with role %s can not add files", userID, *resp.Role))
	}

	collectionOwnerID := resp.Collection.Owner.ID
	filesOwnerID := userID
	// Verify that the user owns each file
	fileIDs := make([]int64, 0)
	for _, file := range files {
		fileIDs = append(fileIDs, file.ID)
	}
	err = c.AccessCtrl.VerifyFileOwnership(ctx, &access.VerifyFileOwnershipParams{
		ActorUserId: userID,
		FileIDs:     fileIDs,
	})

	if err != nil {
		return stacktrace.Propagate(err, "Failed to verify fileOwnership")
	}
	err = c.CollectionRepo.AddFiles(cID, collectionOwnerID, files, filesOwnerID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

// RestoreFiles restore files from trash and add to the collection
func (c *CollectionController) RestoreFiles(ctx *gin.Context, userID int64, cID int64, files []ente.CollectionFileItem) error {
	_, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID:   cID,
		ActorUserID:    userID,
		IncludeDeleted: false,
		VerifyOwner:    true,
	})
	if err != nil {
		return stacktrace.Propagate(err, "failed to verify collection access")
	}
	// Verify that the user owns each file
	for _, file := range files {
		// todo #perf find owners of all files
		ownerID, err := c.FileRepo.GetOwnerID(file.ID)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		if ownerID != userID {
			log.WithFields(log.Fields{
				"file_id":  file.ID,
				"owner_id": ownerID,
				"user_id":  userID,
			}).Error("invalid ops: can't add file which isn't owned by user")
			return stacktrace.Propagate(ente.ErrPermissionDenied, "")
		}
	}
	err = c.CollectionRepo.RestoreFiles(ctx, userID, cID, files)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

// MoveFiles from one collection to another collection. Both the collections and files should belong to
// single user
func (c *CollectionController) MoveFiles(ctx *gin.Context, req ente.MoveFilesRequest) error {
	userID := auth.GetUserID(ctx.Request.Header)
	_, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID:   req.FromCollectionID,
		ActorUserID:    userID,
		IncludeDeleted: false,
		VerifyOwner:    true,
	})
	if err != nil {
		return stacktrace.Propagate(err, "failed to verify if actor owns fromCollection")
	}

	_, err = c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID:   req.ToCollectionID,
		ActorUserID:    userID,
		IncludeDeleted: false,
		VerifyOwner:    true,
	})
	if err != nil {
		return stacktrace.Propagate(err, "failed to verify if actor owns toCollection")
	}

	// Verify that the user owns each file
	fileIDs := make([]int64, 0)
	for _, file := range req.Files {
		fileIDs = append(fileIDs, file.ID)
	}
	err = c.AccessCtrl.VerifyFileOwnership(ctx, &access.VerifyFileOwnershipParams{
		ActorUserId: userID,
		FileIDs:     fileIDs,
	})
	if err != nil {
		return stacktrace.Propagate(err, "Failed to verify fileOwnership")
	}
	err = c.CollectionRepo.MoveFiles(ctx, req.ToCollectionID, req.FromCollectionID, req.Files, userID, userID)
	return stacktrace.Propagate(err, "") // return nil if err is nil
}

// RemoveFilesV3 removes files from a collection as long as owner(s) of the file is different from collection owner
func (c *CollectionController) RemoveFilesV3(ctx *gin.Context, req ente.RemoveFilesV3Request) error {
	actorUserID := auth.GetUserID(ctx.Request.Header)
	resp, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID: req.CollectionID,
		ActorUserID:  actorUserID,
		VerifyOwner:  false,
	})
	if err != nil {
		return stacktrace.Propagate(err, "failed to verify collection access")
	}
	err = c.isRemoveAllowed(ctx, actorUserID, resp.Collection.Owner.ID, resp.Role, req.FileIDs)
	if err != nil {
		return stacktrace.Propagate(err, "file removal check failed")
	}
	err = c.CollectionRepo.RemoveFilesV3(ctx, req.CollectionID, req.FileIDs)
	if err != nil {
		return stacktrace.Propagate(err, "failed to remove files")
	}
	return nil
}

// isRemoveAllowed verifies that given set of files can be removed from the collection or not
func (c *CollectionController) isRemoveAllowed(ctx *gin.Context, actorUserID int64, collectionOwnerID int64, role *ente.CollectionParticipantRole, fileIDs []int64) error {
	ownerToFilesMap, err := c.FileRepo.GetOwnerToFileIDsMap(ctx, fileIDs)
	if err != nil {
		return stacktrace.Propagate(err, "failed to get owner to fileIDs map")
	}
	// verify that none of the file belongs to the collection owner
	if _, ok := ownerToFilesMap[collectionOwnerID]; ok {
		return ente.NewBadRequestWithMessage("can not remove files owned by album owner")
	}

	if collectionOwnerID == actorUserID {
		return nil
	}

	if role != nil && *role == ente.ADMIN {
		return nil
	}

	// verify that user is only trying to remove files owned by them
	if len(ownerToFilesMap) > 1 {
		return stacktrace.Propagate(ente.ErrPermissionDenied, "can not remove files owned by others")
	}
	// verify that user is only trying to remove files owned by them
	if _, ok := ownerToFilesMap[actorUserID]; !ok {
		return stacktrace.Propagate(ente.ErrPermissionDenied, "can not remove files owned by others")
	}
	return nil
}

func (c *CollectionController) IsCopyAllowed(ctx *gin.Context, actorUserID int64, req ente.CopyFileSyncRequest) error {
	// verify that srcCollectionID is accessible by actorUserID
	if _, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID: req.SrcCollectionID,
		ActorUserID:  actorUserID,
	}); err != nil {
		return stacktrace.Propagate(err, "failed to verify srcCollection access")
	}
	// verify that dstCollectionID is owned by actorUserID
	if _, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID: req.DstCollection,
		ActorUserID:  actorUserID,
		VerifyOwner:  true,
	}); err != nil {
		return stacktrace.Propagate(err, "failed to ownership of the dstCollection access")
	}
	// verify that all FileIDs exists in the srcCollection
	fileIDs := make([]int64, len(req.CollectionFileItems))
	for idx, file := range req.CollectionFileItems {
		fileIDs[idx] = file.ID
	}
	if err := c.CollectionRepo.VerifyAllFileIDsExistsInCollection(ctx, req.SrcCollectionID, fileIDs); err != nil {
		return stacktrace.Propagate(err, "failed to verify fileIDs in srcCollection")
	}
	dsMap, err := c.FileRepo.GetOwnerToFileIDsMap(ctx, fileIDs)
	if err != nil {
		return err
	}
	// verify that none of the file belongs to actorUserID
	if _, ok := dsMap[actorUserID]; ok {
		return ente.NewBadRequestWithMessage("can not copy files owned by actor")
	}
	return nil
}
