package collections

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-contrib/requestid"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

func (c *CollectionController) GetCastCollection(ctx *gin.Context) (*ente.Collection, error) {
	castCtx := auth.GetCastCtx(ctx)
	collection, err := c.CollectionRepo.Get(castCtx.CollectionID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if collection.IsDeleted {
		return nil, stacktrace.Propagate(ente.ErrNotFound, "collection is deleted")
	}
	return &collection, nil
}

// GetCastDiff returns the changes in the collections since a timestamp, along with hasMore bool flag.
func (c *CollectionController) GetCastDiff(ctx *gin.Context, sinceTime int64) ([]ente.File, bool, error) {
	castCtx := auth.GetCastCtx(ctx)
	collectionID := castCtx.CollectionID
	reqContextLogger := log.WithFields(log.Fields{
		"collection_id": collectionID,
		"since_time":    sinceTime,
		"req_id":        requestid.Get(ctx),
	})
	diff, hasMore, err := c.getDiff(collectionID, sinceTime, CollectionDiffLimit, reqContextLogger)
	if err != nil {
		return nil, false, stacktrace.Propagate(err, "")
	}
	// hide private metadata before returning files info in diff
	for idx := range diff {
		if diff[idx].MagicMetadata != nil {
			diff[idx].MagicMetadata = nil
		}
		// For cast diffs, treat action markers as deleted and strip action details
		if diff[idx].Action != nil && !diff[idx].IsDeleted {
			if *diff[idx].Action == ente.ActionRemove || *diff[idx].Action == ente.ActionDeleteSuggested {
				diff[idx].IsDeleted = true
			}
		}
		diff[idx].Action = nil
		diff[idx].ActionUserID = nil
	}
	return diff, hasMore, nil
}
