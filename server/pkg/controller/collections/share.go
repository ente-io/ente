package collections

import (
	"context"
	"fmt"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/access"
	"github.com/ente-io/museum/pkg/utils/array"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/gin-contrib/requestid"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
	"strings"
)

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
	err = c.BillingCtrl.HasActiveSelfOrFamilySubscription(fromUserID, true)
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

func (c *CollectionController) JoinViaLink(ctx *gin.Context, req ente.JoinCollectionViaLinkRequest) error {
	userID := auth.GetUserID(ctx.Request.Header)
	collection, err := c.CollectionRepo.Get(req.CollectionID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if collection.Owner.ID == userID {
		return stacktrace.Propagate(ente.ErrBadRequest, "owner can not join via link")
	}
	if !collection.AllowSharing() {
		return stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("joining %s is not allowed", collection.Type))
	}
	collectionLinkToken, err := c.CollectionLinkCtrl.GetActiveCollectionLinkToken(ctx, req.CollectionID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}

	if canJoin := collectionLinkToken.CanJoin(); canJoin != nil {
		return stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("can not join collection: %s", canJoin.Error()))
	}
	accessToken := auth.GetAccessToken(ctx)
	if collectionLinkToken.Token != accessToken {
		return stacktrace.Propagate(ente.ErrPermissionDenied, "token doesn't match collection")
	}
	if collectionLinkToken.PassHash != nil && *collectionLinkToken.PassHash != "" {
		accessTokenJWT := auth.GetAccessTokenJWT(ctx)
		if passCheckErr := c.CollectionLinkCtrl.ValidateJWTToken(ctx, accessTokenJWT, *collectionLinkToken.PassHash); passCheckErr != nil {
			return stacktrace.Propagate(passCheckErr, "")
		}
	}
	err = c.BillingCtrl.HasActiveSelfOrFamilySubscription(collection.Owner.ID, true)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	role := ente.VIEWER
	if collectionLinkToken.EnableCollect {
		role = ente.COLLABORATOR
	}
	joinErr := c.CollectionRepo.Share(req.CollectionID, collection.Owner.ID, userID, req.EncryptedKey, role, time.Microseconds())
	if joinErr != nil {
		return stacktrace.Propagate(joinErr, "")
	}
	go c.EmailCtrl.OnLinkJoined(collection.Owner.ID, userID, role)
	return nil
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
	err = c.BillingCtrl.HasActiveSelfOrFamilySubscription(userID, true)
	if err != nil {
		return ente.PublicURL{}, stacktrace.Propagate(err, "")
	}
	response, err := c.CollectionLinkCtrl.CreateLink(ctx, req)
	if err != nil {
		return ente.PublicURL{}, stacktrace.Propagate(err, "")
	}
	return response, nil
}

// UpdateShareURL updates the shared url configuration
func (c *CollectionController) UpdateShareURL(
	ctx context.Context,
	userID int64,
	req ente.UpdatePublicAccessTokenRequest,
) (*ente.PublicURL, error) {
	if err := req.Validate(); err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if err := c.verifyOwnership(req.CollectionID, userID); err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	err := c.BillingCtrl.HasActiveSelfOrFamilySubscription(userID, true)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	response, err := c.CollectionLinkCtrl.UpdateSharedUrl(ctx, req)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &response, nil
}

// DisableSharedURL disable a public auth-token for the given collectionID
func (c *CollectionController) DisableSharedURL(ctx context.Context, userID int64, cID int64) error {
	if err := c.verifyOwnership(cID, userID); err != nil {
		return stacktrace.Propagate(err, "")
	}
	err := c.CollectionLinkCtrl.Disable(ctx, cID)
	return stacktrace.Propagate(err, "")
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
