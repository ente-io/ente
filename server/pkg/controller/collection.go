package controller

import (
	"context"
	"encoding/json"
	"fmt"
	"github.com/ente-io/museum/pkg/repo/cast"
	"runtime/debug"
	"strings"

	"github.com/ente-io/museum/pkg/controller/access"
	"github.com/gin-contrib/requestid"
	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"

	"github.com/ente-io/museum/pkg/utils/array"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/gin-gonic/gin"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	log "github.com/sirupsen/logrus"
)

const (
	CollectionDiffLimit = 2500
)

// CollectionController encapsulates logic that deals with collections
type CollectionController struct {
	PublicCollectionCtrl *PublicCollectionController
	AccessCtrl           access.Controller
	BillingCtrl          *BillingController
	CollectionRepo       *repo.CollectionRepository
	UserRepo             *repo.UserRepository
	FileRepo             *repo.FileRepository
	QueueRepo            *repo.QueueRepository
	CastRepo             *cast.Repository
	TaskRepo             *repo.TaskLockRepository
}

// Create creates a collection
func (c *CollectionController) Create(collection ente.Collection, ownerID int64) (ente.Collection, error) {
	// The key attribute check is to ensure that user does not end up uploading any files before actually setting the key attributes.
	if _, keyErr := c.UserRepo.GetKeyAttributes(ownerID); keyErr != nil {
		return ente.Collection{}, stacktrace.Propagate(keyErr, "Unable to get keyAttributes")
	}
	collectionType := collection.Type
	collection.Owner.ID = ownerID
	collection.UpdationTime = time.Microseconds()
	// [20th Dec 2022] Patch on server side untill majority of the existing mobile clients upgrade to a version higher > 0.7.0
	// https://github.com/ente-io/photos-app/pull/725
	if collection.Type == "CollectionType.album" {
		collection.Type = "album"
	}
	if !array.StringInList(collection.Type, ente.ValidCollectionTypes) {
		return ente.Collection{}, stacktrace.Propagate(fmt.Errorf("unexpected collection type %s", collection.Type), "")
	}
	collection, err := c.CollectionRepo.Create(collection)
	if err != nil {
		if err == ente.ErrUncategorizeCollectionAlreadyExists || err == ente.ErrFavoriteCollectionAlreadyExist {
			dbCollection, err := c.CollectionRepo.GetCollectionByType(ownerID, collectionType)
			if err != nil {
				return ente.Collection{}, stacktrace.Propagate(err, "")
			}
			if dbCollection.IsDeleted {
				return ente.Collection{}, stacktrace.Propagate(fmt.Errorf("special collection of type : %s is deleted", collectionType), "")
			}
			return dbCollection, nil
		}
		return ente.Collection{}, stacktrace.Propagate(err, "")
	}
	return collection, nil
}

// GetOwned returns the list of collections owned by a user
func (c *CollectionController) GetOwned(userID int64, sinceTime int64, app ente.App) ([]ente.Collection, error) {
	collections, err := c.CollectionRepo.GetCollectionsOwnedByUser(userID, sinceTime, app)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	go func() {
		defer func() {
			if r := recover(); r != nil {
				log.Errorf("Panic caught: %s, stack: %s", r, string(debug.Stack()))
			}
		}()
		collectionsV2, errV2 := c.CollectionRepo.GetCollectionsOwnedByUserV2(userID, sinceTime, app)
		if errV2 != nil {
			log.WithError(errV2).Error("failed to fetch collections using v2")
		}
		isEqual := cmp.Equal(collections, collectionsV2, cmpopts.SortSlices(func(a, b ente.Collection) bool { return a.ID < b.ID }))
		if !isEqual {
			jsonV1, _ := json.Marshal(collections)
			jsonV2, _ := json.Marshal(collectionsV2)
			log.WithFields(log.Fields{
				"v1": string(jsonV1),
				"v2": string(jsonV2),
			}).Error("collections diff didn't match")
		} else {
			log.Info("collections diff matched")
		}
	}()
	return collections, nil
}

// GetOwnedV2 returns the list of collections owned by a user using optimized query
func (c *CollectionController) GetOwnedV2(userID int64, sinceTime int64, app ente.App) ([]ente.Collection, error) {
	collections, err := c.CollectionRepo.GetCollectionsOwnedByUserV2(userID, sinceTime, app)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return collections, nil
}

// GetCollection returns the collection for given collectionID
func (c *CollectionController) GetCollection(ctx *gin.Context, userID int64, cID int64) (ente.Collection, error) {
	resp, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID:   cID,
		ActorUserID:    userID,
		IncludeDeleted: true,
	})
	if err != nil {
		return ente.Collection{}, stacktrace.Propagate(err, "")
	}
	return resp.Collection, nil
}

// GetSharedWith returns the list of collections that are shared with a user
func (c *CollectionController) GetSharedWith(userID int64, sinceTime int64, app ente.App) ([]ente.Collection, error) {
	collections, err := c.CollectionRepo.GetCollectionsSharedWithUser(userID, sinceTime, app)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return collections, nil
}

// Share shares a collection with a user
func (c *CollectionController) Share(ctx *gin.Context, req ente.AlterShareRequest) ([]ente.CollectionUser, error) {
	fromUserID := auth.GetUserID(ctx.Request.Header)
	cID := req.CollectionID
	encryptedKey := req.EncryptedKey
	toUserEmail := strings.ToLower(strings.TrimSpace(req.Email))
	// default role type
	role := ente.VIEWER
	if req.Role != nil {
		role = *req.Role
	}

	toUserID, err := c.UserRepo.GetUserIDWithEmail(toUserEmail)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if toUserID == fromUserID {
		return nil, stacktrace.Propagate(ente.ErrBadRequest, "Can not share collection with self")
	}
	collection, err := c.CollectionRepo.Get(cID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if !collection.AllowSharing() {
		return nil, stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("sharing %s is not allowed", collection.Type))
	}
	if fromUserID != collection.Owner.ID {
		return nil, stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
	err = c.BillingCtrl.HasActiveSelfOrFamilySubscription(fromUserID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	err = c.CollectionRepo.Share(cID, fromUserID, toUserID, encryptedKey, role, time.Microseconds())
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	sharees, err := c.GetSharees(ctx, cID, fromUserID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return sharees, nil
}

// UnShare unshares a collection with a user
func (c *CollectionController) UnShare(ctx *gin.Context, cID int64, fromUserID int64, toUserEmail string) ([]ente.CollectionUser, error) {
	toUserID, err := c.UserRepo.GetUserIDWithEmail(toUserEmail)
	if err != nil {
		return nil, stacktrace.Propagate(ente.ErrNotFound, "")
	}
	collection, err := c.CollectionRepo.Get(cID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	isLeavingCollection := toUserID == fromUserID
	if fromUserID != collection.Owner.ID || isLeavingCollection {
		return nil, stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
	err = c.CollectionRepo.UnShare(cID, toUserID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	err = c.CastRepo.RevokeForGivenUserAndCollection(ctx, cID, toUserID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	sharees, err := c.GetSharees(ctx, cID, fromUserID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return sharees, nil
}

// Leave leaves the collection owned by someone else,
func (c *CollectionController) Leave(ctx *gin.Context, cID int64) error {
	userID := auth.GetUserID(ctx.Request.Header)
	collection, err := c.CollectionRepo.Get(cID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if userID == collection.Owner.ID {
		return stacktrace.Propagate(ente.ErrPermissionDenied, "can not leave collection owned by self")
	}
	sharedCollectionIDs, err := c.CollectionRepo.GetCollectionIDsSharedWithUser(userID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if !array.Int64InList(cID, sharedCollectionIDs) {
		return nil
	}
	err = c.CastRepo.RevokeForGivenUserAndCollection(ctx, cID, userID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	err = c.CollectionRepo.UnShare(cID, userID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

func (c *CollectionController) UpdateShareeMagicMetadata(ctx *gin.Context, req ente.UpdateCollectionMagicMetadata) error {
	actorUserId := auth.GetUserID(ctx.Request.Header)
	resp, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID: req.ID,
		ActorUserID:  actorUserId,
	})
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if resp.Collection.Owner.ID == actorUserId {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage("owner can not update sharee magic metadata"), "")
	}
	err = c.CollectionRepo.UpdateShareeMetadata(req.ID, resp.Collection.Owner.ID, actorUserId, req.MagicMetadata, time.Microseconds())
	if err != nil {
		return stacktrace.Propagate(err, "failed to update sharee magic metadata")
	}
	return nil
}

// ShareURL generates a public auth-token for the given collectionID
func (c *CollectionController) ShareURL(ctx context.Context, userID int64, req ente.CreatePublicAccessTokenRequest) (
	ente.PublicURL, error) {
	collection, err := c.CollectionRepo.Get(req.CollectionID)
	if err != nil {
		return ente.PublicURL{}, stacktrace.Propagate(err, "")
	}
	if !collection.AllowSharing() {
		return ente.PublicURL{}, stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("sharing %s is not allowed", collection.Type))
	}
	if userID != collection.Owner.ID {
		return ente.PublicURL{}, stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
	err = c.BillingCtrl.HasActiveSelfOrFamilySubscription(userID)
	if err != nil {
		return ente.PublicURL{}, stacktrace.Propagate(err, "")
	}
	response, err := c.PublicCollectionCtrl.CreateAccessToken(ctx, req)
	if err != nil {
		return ente.PublicURL{}, stacktrace.Propagate(err, "")
	}
	return response, nil
}

// UpdateShareURL updates the shared url configuration
func (c *CollectionController) UpdateShareURL(ctx context.Context, userID int64, req ente.UpdatePublicAccessTokenRequest) (
	ente.PublicURL, error) {
	if err := c.verifyOwnership(req.CollectionID, userID); err != nil {
		return ente.PublicURL{}, stacktrace.Propagate(err, "")
	}
	err := c.BillingCtrl.HasActiveSelfOrFamilySubscription(userID)
	if err != nil {
		return ente.PublicURL{}, stacktrace.Propagate(err, "")
	}
	response, err := c.PublicCollectionCtrl.UpdateSharedUrl(ctx, req)
	if err != nil {
		return ente.PublicURL{}, stacktrace.Propagate(err, "")
	}
	return response, nil
}

// DisableSharedURL disable a public auth-token for the given collectionID
func (c *CollectionController) DisableSharedURL(ctx context.Context, userID int64, cID int64) error {
	if err := c.verifyOwnership(cID, userID); err != nil {
		return stacktrace.Propagate(err, "")
	}
	err := c.PublicCollectionCtrl.Disable(ctx, cID)
	return stacktrace.Propagate(err, "")
}

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
		stacktrace.Propagate(err, "Failed to verify fileOwnership")
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
	err = c.isRemoveAllowed(ctx, actorUserID, resp.Collection.Owner.ID, req.FileIDs)
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
func (c *CollectionController) isRemoveAllowed(ctx *gin.Context, actorUserID int64, collectionOwnerID int64, fileIDs []int64) error {
	ownerToFilesMap, err := c.FileRepo.GetOwnerToFileIDsMap(ctx, fileIDs)
	if err != nil {
		return stacktrace.Propagate(err, "failed to get owner to fileIDs map")
	}
	// verify that none of the file belongs to the collection owner
	if _, ok := ownerToFilesMap[collectionOwnerID]; ok {
		return ente.NewBadRequestWithMessage("can not remove files owned by album owner")
	}

	if collectionOwnerID != actorUserID {
		// verify that user is only trying to remove files owned by them
		if len(ownerToFilesMap) > 1 {
			return stacktrace.Propagate(ente.ErrPermissionDenied, "can not remove files owned by others")
		}
		// verify that user is only trying to remove files owned by them
		if _, ok := ownerToFilesMap[actorUserID]; !ok {
			return stacktrace.Propagate(ente.ErrPermissionDenied, "can not remove files owned by others")
		}
	}
	return nil
}

// GetDiffV2 returns the changes in user's collections since a timestamp, along with hasMore bool flag.
func (c *CollectionController) GetDiffV2(ctx *gin.Context, cID int64, userID int64, sinceTime int64) ([]ente.File, bool, error) {
	reqContextLogger := log.WithFields(log.Fields{
		"user_id":       userID,
		"collection_id": cID,
		"since_time":    sinceTime,
		"req_id":        requestid.Get(ctx),
	})
	_, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID: cID,
		ActorUserID:  userID,
	})
	if err != nil {
		return nil, false, stacktrace.Propagate(err, "failed to verify access")
	}
	diff, hasMore, err := c.getDiff(cID, sinceTime, CollectionDiffLimit, reqContextLogger)
	if err != nil {
		return nil, false, stacktrace.Propagate(err, "")
	}
	// hide private metadata before returning files info in diff
	for idx := range diff {
		if diff[idx].OwnerID != userID {
			diff[idx].MagicMetadata = nil
		}
		if diff[idx].Metadata.EncryptedData == "-" && !diff[idx].IsDeleted {
			// This indicates that the file is deleted, but we still have a stale entry in the collection
			log.WithFields(log.Fields{
				"file_id":       diff[idx].ID,
				"collection_id": cID,
				"updated_at":    diff[idx].UpdationTime,
			}).Warning("stale collection_file found")
			diff[idx].IsDeleted = true
		}
	}
	return diff, hasMore, nil
}

func (c *CollectionController) GetFile(ctx *gin.Context, collectionID int64, fileID int64) (*ente.File, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	files, err := c.CollectionRepo.GetFile(collectionID, fileID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if len(files) == 0 {
		return nil, stacktrace.Propagate(&ente.ErrFileNotFoundInAlbum, "")
	}

	file := files[0]
	if file.OwnerID != userID {
		cIDs, err := c.CollectionRepo.GetCollectionIDsSharedWithUser(userID)
		if err != nil {
			return nil, stacktrace.Propagate(err, "")
		}
		if !array.Int64InList(collectionID, cIDs) {
			return nil, stacktrace.Propagate(ente.ErrPermissionDenied, "")
		}
	}
	if file.IsDeleted {
		return nil, stacktrace.Propagate(&ente.ErrFileNotFoundInAlbum, "")
	}
	return &file, nil
}

// GetPublicDiff returns the changes in the collections since a timestamp, along with hasMore bool flag.
func (c *CollectionController) GetPublicDiff(ctx *gin.Context, sinceTime int64) ([]ente.File, bool, error) {
	accessContext := auth.MustGetPublicAccessContext(ctx)
	reqContextLogger := log.WithFields(log.Fields{
		"public_id":     accessContext.ID,
		"collection_id": accessContext.CollectionID,
		"since_time":    sinceTime,
		"req_id":        requestid.Get(ctx),
	})
	diff, hasMore, err := c.getDiff(accessContext.CollectionID, sinceTime, CollectionDiffLimit, reqContextLogger)
	if err != nil {
		return nil, false, stacktrace.Propagate(err, "")
	}
	// hide private metadata before returning files info in diff
	for idx := range diff {
		if diff[idx].MagicMetadata != nil {
			diff[idx].MagicMetadata = nil
		}
	}
	return diff, hasMore, nil
}

// getDiff returns the diff in user's collection since a timestamp, along with hasMore bool flag.
// The function will never return partial result for a version. To maintain this promise, it will not be able to honor
// the limit parameter. Based on the db state, compared to the limit, the diff length can be
// less (case 1), more (case 2), or same (case 3, 4)
// Example: Assume we have 11 files with following versions: v0, v1, v1, v1, v1, v1, v1, v1, v2, v2, v2 (count = 7 v1, 3 v2)
// client has synced up till version v0.
// case 1: ( sinceTime: v0, limit = 8):
// The method will discard the entries with version v2 and return only 7 entries with version v1.
// case 2: (sinceTime: v0, limit 5):
// Instead of returning 5 entries with version V1, method will return all 7 entries with version v1.
// case 3: (sinceTime: v0, limit 7):
// The method will return all 7 entries with version V1.
// case 4: (sinceTime: v0, limit >=10):
// The method will all 10 entries in the diff
func (c *CollectionController) getDiff(cID int64, sinceTime int64, limit int, logger *log.Entry) ([]ente.File, bool, error) {
	// request for limit +1 files
	diffLimitPlusOne, err := c.CollectionRepo.GetDiff(cID, sinceTime, limit+1)
	if err != nil {
		return nil, false, stacktrace.Propagate(err, "")
	}
	if len(diffLimitPlusOne) <= limit {
		// case 4: all files changed after sinceTime are included.
		return diffLimitPlusOne, false, nil
	}
	lastFileVersion := diffLimitPlusOne[limit].UpdationTime
	filteredDiffs := c.removeFilesWithVersion(diffLimitPlusOne, lastFileVersion)
	filteredDiffLen := len(filteredDiffs)

	if filteredDiffLen > 0 { // case 1 or case 3
		if filteredDiffLen < limit {
			// logging case 1
			logger.
				WithField("last_file_version", lastFileVersion).
				WithField("filtered_diff_len", filteredDiffLen).
				Info(fmt.Sprintf("less than limit (%d) files in diff", limit))
		}
		return filteredDiffs, true, nil
	}
	// case 2
	diff, err := c.CollectionRepo.GetFilesWithVersion(cID, lastFileVersion)
	logger.
		WithField("last_file_version", lastFileVersion).
		WithField("count", len(diff)).
		Info(fmt.Sprintf("more than limit (%d) files with same version", limit))
	if err != nil {
		return nil, false, stacktrace.Propagate(err, "")
	}
	return diff, true, nil
}

// removeFilesWithVersion returns filtered list of files are removing all files with given version.
// Important: The method assumes that files are sorted by increasing order of File.UpdationTime
func (c *CollectionController) removeFilesWithVersion(files []ente.File, version int64) []ente.File {
	var i = len(files) - 1
	for ; i >= 0; i-- {
		if files[i].UpdationTime != version {
			// found index (from end) where file's version is different from given version
			break
		}
	}
	return files[0 : i+1]
}

// GetSharees returns the list of users a collection has been shared with
func (c *CollectionController) GetSharees(ctx *gin.Context, cID int64, userID int64) ([]ente.CollectionUser, error) {
	_, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID: cID,
		ActorUserID:  userID,
	})
	if err != nil {
		return nil, stacktrace.Propagate(err, "Access check failed")
	}
	sharees, err := c.CollectionRepo.GetSharees(cID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return sharees, nil
}

// TrashV3 deletes a given collection and based on user input (TrashCollectionV3Request.KeepFiles as FALSE) , it will move all files present in the underlying collection
// to trash.
func (c *CollectionController) TrashV3(ctx *gin.Context, req ente.TrashCollectionV3Request) error {
	if req.KeepFiles == nil {
		return ente.ErrBadRequest
	}
	userID := auth.GetUserID(ctx.Request.Header)
	cID := req.CollectionID
	resp, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
		CollectionID:   cID,
		ActorUserID:    userID,
		IncludeDeleted: true,
		VerifyOwner:    true,
	})
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if !resp.Collection.AllowDelete() {
		return stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("deleting albums of type %s is not allowed", resp.Collection.Type))
	}
	if resp.Collection.IsDeleted {
		log.WithFields(log.Fields{
			"c_id":    cID,
			"user_id": userID,
		}).Warning("Collection is already deleted")
		return nil
	}

	if *req.KeepFiles {
		// Verify that all files from this particular collections have been removed.
		count, err := c.CollectionRepo.GetCollectionsFilesCount(cID)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		if count != 0 {
			return stacktrace.Propagate(&ente.ErrCollectionNotEmpty, fmt.Sprintf("Collection file count %d", count))
		}

	}
	err = c.PublicCollectionCtrl.Disable(ctx, cID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to disabled public share url")
	}
	err = c.CastRepo.RevokeTokenForCollection(ctx, cID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to revoke cast token")
	}
	// Continue with current delete flow till. This disables sharing for this collection and then queue it up for deletion
	err = c.CollectionRepo.ScheduleDelete(cID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

// Rename updates the collection's name
func (c *CollectionController) Rename(userID int64, cID int64, encryptedName string, nameDecryptionNonce string) error {
	if err := c.verifyOwnership(cID, userID); err != nil {
		return stacktrace.Propagate(err, "")
	}
	err := c.CollectionRepo.Rename(cID, encryptedName, nameDecryptionNonce)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

// UpdateMagicMetadata updates the magic metadata for given collection
func (c *CollectionController) UpdateMagicMetadata(ctx *gin.Context, request ente.UpdateCollectionMagicMetadata, isPublicMetadata bool) error {
	userID := auth.GetUserID(ctx.Request.Header)
	if err := c.verifyOwnership(request.ID, userID); err != nil {
		return stacktrace.Propagate(err, "")
	}
	// todo: verify version mismatch later. We are not planning to resync collection on clients,
	// so ignore that check until then. Ideally, after file size info sync, we should enable
	err := c.CollectionRepo.UpdateMagicMetadata(ctx, request.ID, request.MagicMetadata, isPublicMetadata)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

func (c *CollectionController) HandleAccountDeletion(ctx context.Context, userID int64, logger *log.Entry) error {
	logger.Info("disabling shared collections with or by the user")
	sharedCollections, err := c.CollectionRepo.GetAllSharedCollections(ctx, userID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	logger.Info(fmt.Sprintf("shared collections count: %d", len(sharedCollections)))
	for _, shareCollection := range sharedCollections {
		logger.WithField("shared_collection", shareCollection).Info("disable shared collection")
		err = c.CollectionRepo.UnShare(shareCollection.CollectionID, shareCollection.ToUserID)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
	}
	err = c.CastRepo.RevokeTokenForUser(ctx, userID)
	if err != nil {
		return stacktrace.Propagate(err, "failed to revoke cast token for user")
	}
	err = c.PublicCollectionCtrl.HandleAccountDeletion(ctx, userID, logger)
	return stacktrace.Propagate(err, "")
}

// Verify that user owns the collection
func (c *CollectionController) verifyOwnership(cID int64, userID int64) error {
	collection, err := c.CollectionRepo.Get(cID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if userID != collection.Owner.ID {
		return stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
	return nil
}
