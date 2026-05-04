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
	app := auth.GetApp(ctx)
	if resp.Collection.App != string(app) {
		return stacktrace.Propagate(ente.ErrInvalidApp, fmt.Sprintf("app mismatch collection: %s  request ctx app %s", resp.Collection.App, app))
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

	// Verify that none of the files are in trash or permanently deleted
	trashedOrDeletedFileIDs, err := c.TrashRepo.GetFilesInTrashOrDeleted(ctx, userID, fileIDs)
	if err != nil {
		return stacktrace.Propagate(err, "failed to check trash state")
	}
	if len(trashedOrDeletedFileIDs) > 0 {
		log.WithFields(log.Fields{
			"user_id":                    userID,
			"collection_id":              cID,
			"trashed_or_deleted_file_ids": trashedOrDeletedFileIDs,
		}).Warn("attempt to add trashed or deleted files to collection")
		return stacktrace.Propagate(&ente.ErrFileInTrash, "")
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
	r1, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID:   req.FromCollectionID,
		ActorUserID:    userID,
		IncludeDeleted: false,
		VerifyOwner:    true,
	})
	if err != nil {
		return stacktrace.Propagate(err, "failed to verify if actor owns fromCollection")
	}

	r2, err2 := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID:   req.ToCollectionID,
		ActorUserID:    userID,
		IncludeDeleted: false,
		VerifyOwner:    true,
	})
	if err2 != nil {
		return stacktrace.Propagate(err2, "failed to verify if actor owns toCollection")
	}

	if r2.Collection.App != r1.Collection.App {
		return stacktrace.Propagate(ente.ErrInvalidApp, fmt.Sprintf("move across app not supported %s to %s", r1.Collection.App, r2.Collection.App))
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

	// Verify that none of the files are in trash or permanently deleted
	trashedOrDeletedFileIDs, err := c.TrashRepo.GetFilesInTrashOrDeleted(ctx, userID, fileIDs)
	if err != nil {
		return stacktrace.Propagate(err, "failed to check trash state")
	}
	if len(trashedOrDeletedFileIDs) > 0 {
		log.WithFields(log.Fields{
			"user_id":                     userID,
			"from_collection_id":          req.FromCollectionID,
			"to_collection_id":            req.ToCollectionID,
			"trashed_or_deleted_file_ids": trashedOrDeletedFileIDs,
		}).Warn("attempt to move trashed or deleted files between collections")
		return stacktrace.Propagate(&ente.ErrFileInTrash, "")
	}

	err = c.CollectionRepo.MoveFiles(ctx, req.ToCollectionID, req.FromCollectionID, req.Files, userID, userID)
	return stacktrace.Propagate(err, "") // return nil if err is nil
}

// RemoveFilesV3 enforces all removal rules for shared collections:
//  1. accessCtrl must confirm the actor participates in the collection;
//  2. collaborators/viewers may only remove files they themselves added
//     (added_by_user_id == actor) — note this is decoupled from file
//     ownership: a collaborator-uploaded file is owned by the album owner
//     but added_by remains the collaborator;
//  3. the collection owner may remove files added by others but never the
//     ones they added themselves (those go through Trash);
//  4. admins can remove anyone's files; files originally added by the
//     collection owner are queued for removal (REMOVE action + pending
//     collection_action entry) so the owner can act on them;
//  5. once the validations pass, non-owner-uploaded files are detached
//     immediately via CollectionRepo.RemoveFilesV3.
func (c *CollectionController) RemoveFilesV3(ctx *gin.Context, actorUserID int64, req ente.RemoveFilesV3Request) error {
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

	// Validate requested files exist in the target collection and filter already-removed ones.
	fileIDsToRemove, err := c.CollectionRepo.FilterActiveFileIDsInCollection(ctx, req.CollectionID, req.FileIDs)
	if err != nil {
		return stacktrace.Propagate(err, "file not found in collection")
	}
	if len(fileIDsToRemove) == 0 {
		return nil
	}
	req.FileIDs = fileIDsToRemove

	// Partition fileIDs by uploader (added_by_user_id, with NULL fallback to f_owner_id).
	addedByMap, err := c.CollectionRepo.GetAddedByMapForCollection(ctx, req.CollectionID, req.FileIDs)
	if err != nil {
		return stacktrace.Propagate(err, "failed to get added_by map")
	}
	ownerUploaded := make([]int64, 0)
	otherUploaded := make([]int64, 0)
	actorUploaded := make([]int64, 0)
	for _, fid := range req.FileIDs {
		addedBy, ok := addedByMap[fid]
		if !ok {
			return stacktrace.NewError(fmt.Sprintf("missing added_by for file %d in collection %d", fid, req.CollectionID))
		}
		switch addedBy {
		case actorUserID:
			actorUploaded = append(actorUploaded, fid)
		case collectionOwnerID:
			ownerUploaded = append(ownerUploaded, fid)
		default:
			otherUploaded = append(otherUploaded, fid)
		}
	}
	if err := c.isRemoveAllowedByUploader(actorUserID, collectionOwnerID, role, actorUploaded, ownerUploaded, otherUploaded); err != nil {
		return stacktrace.Propagate(err, "file removal check failed")
	}

	// ADMIN suggesting removal of owner-uploaded files: queue suggest-action
	// rather than detach immediately.
	if len(ownerUploaded) > 0 {
		if role != nil && *role == ente.ADMIN && actorUserID != collectionOwnerID {
			if err := c.CollectionRepo.SuggestAction(ctx, req.CollectionID, actorUserID, ownerUploaded, ente.ActionRemove); err != nil {
				return stacktrace.Propagate(err, "failed to set remove action for owner's files")
			}
			if err := c.CollectionActionsRepo.CreateBulk(ctx, collectionOwnerID, actorUserID, req.CollectionID, ownerUploaded, nil, ente.ActionRemove, true); err != nil {
				return stacktrace.Propagate(err, "failed to create collection action REMOVE")
			}
		} else {
			// Should be unreachable when isRemoveAllowedByUploader passed.
			return stacktrace.NewError(fmt.Sprintf("actor %d with role %v is not allowed to remove files added by collection owner %d", actorUserID, role, collectionOwnerID))
		}
	}

	// Files added by actor (collaborator/admin removing their own contributions)
	// or by other non-owner participants (owner/admin removing them) are
	// detached immediately.
	immediate := append(actorUploaded, otherUploaded...)
	if len(immediate) > 0 {
		if err := c.CollectionRepo.RemoveFilesV3(ctx, req.CollectionID, collectionOwnerID, immediate); err != nil {
			return stacktrace.Propagate(err, "failed to remove files")
		}
	}
	return nil
}

// SuggestDeleteInSharedCollection allows collection owners/admins to nudge other
// participants to delete their files:
//  1. only OWNER/ADMIN roles pass the access check;
//  2. every file ID must belong to the collection and none may belong to the acting user;
//  3. the method internally reuses RemoveFilesV3 to enforce role-based rules and
//     to actually detach the files from the collection;
//  4. each remote owner then receives DELETE_SUGGESTED actions so their clients
//     can surface the pending delete request.
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
	// Validate fileIDs exist in the collection and filter already-removed ones.
	fileIDsToRemove, err := c.CollectionRepo.FilterActiveFileIDsInCollection(ctx, req.CollectionID, req.FileIDs)
	if err != nil {
		return stacktrace.Propagate(err, "file not found in collection")
	}
	if len(fileIDsToRemove) == 0 {
		return nil
	}
	// Ensure none of the files belong to actor
	ownerMap, err := c.FileRepo.GetOwnerToFileIDsMap(ctx, fileIDsToRemove)
	if err != nil {
		return stacktrace.Propagate(err, "failed to get owner map")
	}
	if _, ok := ownerMap[actorUserID]; ok {
		return stacktrace.Propagate(ente.ErrPermissionDenied, "can not suggest delete for actor-owned files")
	}
	if removeErr := c.RemoveFilesV3(ctx, actorUserID, ente.RemoveFilesV3Request{
		CollectionID: req.CollectionID,
		FileIDs:      fileIDsToRemove,
	}); removeErr != nil {
		return stacktrace.Propagate(removeErr, "failed to remove files")
	}

	for uid, fids := range ownerMap {
		if err := c.CollectionActionsRepo.CreateBulk(ctx, uid, actorUserID, req.CollectionID, fids, nil, ente.ActionDeleteSuggested, true); err != nil {
			return stacktrace.Propagate(err, "failed to create collection actions for owner files")
		}
	}
	return nil
}

// isRemoveAllowedByUploader checks the partition built from added_by_user_id:
//   - actorUploaded — files the actor added themselves
//   - ownerUploaded — files the collection owner added (only when actor != owner)
//   - otherUploaded — files added by some third participant (not actor, not owner)
//
// Rules:
//   - The collection owner cannot remove their own contributions via this
//     path — they must use Trash, which deletes the file globally.
//   - ADMIN can remove anything. Owner-uploaded files are routed through a
//     suggest-action queue by the caller, but pass the permission check here.
//   - The collection owner can remove anything they did not upload.
//   - COLLABORATOR / VIEWER can only remove files they themselves added.
func (c *CollectionController) isRemoveAllowedByUploader(
	actorUserID int64,
	collectionOwnerID int64,
	role *ente.CollectionParticipantRole,
	actorUploaded []int64,
	ownerUploaded []int64,
	otherUploaded []int64) error {

	if actorUserID == collectionOwnerID && len(actorUploaded) > 0 {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage("can not remove files added by collection owner via remove; use trash"), "")
	}
	if role != nil && *role == ente.ADMIN {
		return nil
	}
	if actorUserID == collectionOwnerID {
		return nil
	}
	// COLLABORATOR / VIEWER: only files they added themselves.
	if len(ownerUploaded) > 0 || len(otherUploaded) > 0 {
		return stacktrace.Propagate(ente.ErrPermissionDenied, "can not remove files added by others")
	}
	return nil
}

func (c *CollectionController) IsCopyAllowed(ctx *gin.Context, actorUserID int64, req ente.CopyFileSyncRequest) error {
	// verify that srcCollectionID is accessible by actorUserID
	srcCollection, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID: req.SrcCollectionID,
		ActorUserID:  actorUserID,
	})
	if err != nil {
		return stacktrace.Propagate(err, "failed to verify srcCollection access")
	}
	// Verify that the actor has CanAdd on the destination collection. Mirrors
	// the loosening applied to POST /files: a collaborator may copy into a
	// shared album whose owner pays the storage. file ownership and quota
	// are pinned to the album owner inside FileController.Create.
	dstCollection, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID: req.DstCollection,
		ActorUserID:  actorUserID,
	})
	if err != nil {
		return stacktrace.Propagate(err, "failed to verify dstCollection access")
	}
	if !dstCollection.Role.CanAdd() {
		return stacktrace.Propagate(ente.ErrPermissionDenied, fmt.Sprintf("user %d cannot add files to dst collection %d", actorUserID, req.DstCollection))
	}
	if srcCollection.Collection.App != dstCollection.Collection.App {
		return stacktrace.Propagate(ente.ErrInvalidApp, fmt.Sprintf("copy across app not supported %s to %s", srcCollection.Collection.App, dstCollection.Collection.App))
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
