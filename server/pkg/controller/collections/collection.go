package collections

import (
	"context"
	"fmt"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/controller/access"
	"github.com/ente-io/museum/pkg/controller/email"
	"github.com/ente-io/museum/pkg/repo/cast"
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
	PublicCollectionCtrl *controller.PublicCollectionController
	EmailCtrl            *email.EmailNotificationController
	AccessCtrl           access.Controller
	BillingCtrl          *controller.BillingController
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
