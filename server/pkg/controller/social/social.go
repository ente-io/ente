package social

import (
	"context"
	"sort"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/access"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// Controller combines comments and reactions for unified endpoints.
type Controller struct {
	CommentsRepo   *repo.CommentsRepository
	ReactionsRepo  *repo.ReactionsRepository
	CollectionRepo *repo.CollectionRepository
	AccessCtrl     access.Controller
}

// UnifiedDiffRequest describes paging parameters for the social diff.
type UnifiedDiffRequest struct {
	Actor         Actor
	CollectionID  int64
	Since         int64
	Limit         int
	FileID        *int64
	RequireAccess bool
}

// CollectionCount summarizes activity for a collection.
type CollectionCount struct {
	CollectionID int64 `json:"collectionID"`
	Comments     int64 `json:"comments"`
	Reactions    int64 `json:"reactions"`
}

// UnifiedDiff returns comments and reactions snapshots side by side.
func (c *Controller) UnifiedDiff(ctx *gin.Context, req UnifiedDiffRequest) ([]ente.Comment, []ente.Reaction, bool, bool, error) {
	if req.RequireAccess {
		userID, hasUserID := req.Actor.UserIDValue()
		if !hasUserID || userID <= 0 {
			return nil, nil, false, false, ente.ErrAuthenticationRequired
		}
		if _, err := c.AccessCtrl.GetCollection(ctx, &access.GetCollectionParams{
			CollectionID: req.CollectionID,
			ActorUserID:  userID,
		}); err != nil {
			return nil, nil, false, false, stacktrace.Propagate(err, "")
		}
	}
	comments, moreComments, err := c.CommentsRepo.GetDiff(ctx.Request.Context(), req.CollectionID, req.Since, req.Limit, req.FileID)
	if err != nil {
		return nil, nil, false, false, stacktrace.Propagate(err, "")
	}
	reactions, moreReactions, err := c.ReactionsRepo.GetDiff(ctx.Request.Context(), req.CollectionID, req.Since, req.Limit, req.FileID, nil)
	if err != nil {
		return nil, nil, false, false, stacktrace.Propagate(err, "")
	}
	return comments, reactions, moreComments, moreReactions, nil
}

// CountActiveCollections returns the active counts per collection accessible to the actor.
func (c *Controller) CountActiveCollections(ctx context.Context, userID int64) ([]CollectionCount, error) {
	ownedMap, err := c.CollectionRepo.GetCollectionIDsOwnedByUser(userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	shared, err := c.CollectionRepo.GetCollectionIDsSharedWithUser(userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	collectionIDs := make([]int64, 0, len(ownedMap)+len(shared))
	for id := range ownedMap {
		collectionIDs = append(collectionIDs, id)
	}
	for _, id := range shared {
		if _, ok := ownedMap[id]; ok {
			continue
		}
		collectionIDs = append(collectionIDs, id)
	}
	if len(collectionIDs) == 0 {
		return nil, nil
	}
	commentCounts, err := c.CommentsRepo.CountActiveByCollection(ctx, collectionIDs)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	reactionCounts, err := c.ReactionsRepo.CountActiveByCollection(ctx, collectionIDs)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	results := make([]CollectionCount, 0, len(collectionIDs))
	sort.Slice(collectionIDs, func(i, j int) bool {
		return collectionIDs[i] < collectionIDs[j]
	})
	seen := map[int64]struct{}{}
	for _, id := range collectionIDs {
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		results = append(results, CollectionCount{
			CollectionID: id,
			Comments:     commentCounts[id],
			Reactions:    reactionCounts[id],
		})
	}
	return results, nil
}
