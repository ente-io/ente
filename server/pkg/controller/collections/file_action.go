package collections

import (
    "fmt"
    "github.com/ente-io/museum/ente"
    "github.com/ente-io/museum/pkg/controller/access"
    "github.com/ente-io/museum/pkg/utils/auth"
    time "github.com/ente-io/museum/pkg/utils/time"
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
    accessResp, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
        CollectionID: req.CollectionID,
        ActorUserID:  actorUserID,
        VerifyOwner:  false,
    })
    if err != nil {
        return stacktrace.Propagate(err, "failed to verify collection access")
    }

    collectionOwnerID := accessResp.Collection.Owner.ID
    role := accessResp.Role

    // Partition fileIDs by owner
    ownerToFilesMap, err := c.FileRepo.GetOwnerToFileIDsMap(ctx, req.FileIDs)
    if err != nil {
        return stacktrace.Propagate(err, "failed to get owner to fileIDs map")
    }
    // Files owned by collection owner
    ownerOwned := ownerToFilesMap[collectionOwnerID]
    // Files owned by others (excluding owner)
    others := make([]int64, 0)
    for _, fid := range req.FileIDs {
        // If not in ownerOwned, it's others
        found := false
        for _, of := range ownerOwned {
            if of == fid { found = true; break }
        }
        if !found {
            others = append(others, fid)
        }
    }

    // If admin is trying to remove owner's files
    if len(ownerOwned) > 0 && role != nil && *role == ente.ADMIN && actorUserID != collectionOwnerID {
        // Populate collection_files with action for owner's files
        if err := c.CollectionRepo.SuggestDelete(ctx, req.CollectionID, actorUserID, ownerOwned, "REMOVE"); err != nil {
            return stacktrace.Propagate(err, "failed to set remove action for owner's files")
        }
        // Create collection actions entries for owner to act (REMOVE) per file
        now := time.Microseconds()
        for i := range ownerOwned {
            fid := ownerOwned[i]
            _, err := c.CollectionActionsRepo.Create(ctx, collectionOwnerID, actorUserID, req.CollectionID, &fid, nil, "REMOVE", true, now)
            if err != nil {
                return stacktrace.Propagate(err, "failed to create collection action REMOVE")
            }
        }
    } else if len(ownerOwned) > 0 {
        // Otherwise enforce existing removal rules
        if err := c.isRemoveAllowed(ctx, actorUserID, collectionOwnerID, role, req.FileIDs); err != nil {
            return stacktrace.Propagate(err, "file removal check failed")
        }
    }

    // Remove files owned by others if allowed
    if len(others) > 0 {
        // Validate removal for others set
        if err := c.isRemoveAllowed(ctx, actorUserID, collectionOwnerID, role, others); err != nil {
            return stacktrace.Propagate(err, "file removal check failed for others")
        }
        if err := c.CollectionRepo.RemoveFilesV3(ctx, req.CollectionID, others); err != nil {
            return stacktrace.Propagate(err, "failed to remove files")
        }
        // Optionally, create pending actions for those owners to delete their files (DELETE_SUGGESTION)
        // Group by owner and create entries
        ownersMap, err := c.FileRepo.GetOwnerToFileIDsMap(ctx, others)
        if err == nil {
            for uid, fids := range ownersMap {
                if uid == actorUserID { continue }
                now := time.Microseconds()
                for i := range fids {
                    fid := fids[i]
                    _, _ = c.CollectionActionsRepo.Create(ctx, uid, actorUserID, req.CollectionID, &fid, nil, "DELETE_SUGGESTED", true, now)
                }
            }
        }
    }
    return nil
}

// SuggestDeleteInSharedCollection sets DELETE_SUGGESTED action for files owned by others.
// Only collection owner or admins can call this. Acting user cannot target their own files.
func (c *CollectionController) SuggestDeleteInSharedCollection(ctx *gin.Context, req ente.SuggestDeleteRequest) error {
    actorUserID := auth.GetUserID(ctx.Request.Header)
    accessResp, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
        CollectionID: req.CollectionID,
        ActorUserID:  actorUserID,
        VerifyOwner:  false,
    })
    if err != nil {
        return stacktrace.Propagate(err, "failed to verify collection access")
    }
    // Only owner or admin can suggest
    if accessResp.Role == nil || (*accessResp.Role != ente.OWNER && *accessResp.Role != ente.ADMIN) {
        return stacktrace.Propagate(ente.ErrPermissionDenied, "role not allowed to suggest delete")
    }
    // Validate all fileIDs exist in the collection
    if err := c.CollectionRepo.VerifyAllFileIDsExistsInCollection(ctx, req.CollectionID, req.FileIDs); err != nil {
        return stacktrace.Propagate(err, "file not found in collection")
    }
    // Ensure none of the files belong to actor
    ownerMap, err := c.FileRepo.GetOwnerToFileIDsMap(ctx, req.FileIDs)
    if err != nil {
        return stacktrace.Propagate(err, "failed to get owner map")
    }
    if _, ok := ownerMap[actorUserID]; ok {
        return stacktrace.Propagate(ente.ErrPermissionDenied, "can not suggest delete for actor-owned files")
    }
    // Partition into owner-owned and others
    ownerID := accessResp.Collection.Owner.ID
    ownersMap, err := c.FileRepo.GetOwnerToFileIDsMap(ctx, req.FileIDs)
    if err != nil {
        return stacktrace.Propagate(err, "failed to get owner map")
    }
    now := time.Microseconds()
    // For owner-owned files: set collection_files actions for both REMOVE and DELETE_SUGGESTED and create pending actions
    if fids, ok := ownersMap[ownerID]; ok {
        if err := c.CollectionRepo.SuggestDelete(ctx, req.CollectionID, actorUserID, fids, "REMOVE"); err != nil {
            return stacktrace.Propagate(err, "failed to set REMOVE action for owner files")
        }
        if err := c.CollectionRepo.SuggestDelete(ctx, req.CollectionID, actorUserID, fids, "DELETE_SUGGESTED"); err != nil {
            return stacktrace.Propagate(err, "failed to set DELETE_SUGGESTED action for owner files")
        }
        for i := range fids {
            fid := fids[i]
            if _, err := c.CollectionActionsRepo.Create(ctx, ownerID, actorUserID, req.CollectionID, &fid, nil, "REMOVE", true, now); err != nil {
                return stacktrace.Propagate(err, "failed to create collection action REMOVE")
            }
            if _, err := c.CollectionActionsRepo.Create(ctx, ownerID, actorUserID, req.CollectionID, &fid, nil, "DELETE_SUGGESTED", true, now); err != nil {
                return stacktrace.Propagate(err, "failed to create collection action DELETE_SUGGESTED")
            }
        }
    }
    // For other owners: remove from collection and create DELETE_SUGGESTED pending action
    for uid, fids := range ownersMap {
        if uid == ownerID || uid == actorUserID { continue }
        if err := c.CollectionRepo.RemoveFilesV3(ctx, req.CollectionID, fids); err != nil {
            return stacktrace.Propagate(err, "failed to remove other owners' files")
        }
        for i := range fids {
            fid := fids[i]
            _, _ = c.CollectionActionsRepo.Create(ctx, uid, actorUserID, req.CollectionID, &fid, nil, "DELETE_SUGGESTED", true, now)
        }
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
