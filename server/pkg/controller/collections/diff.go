package collections

import (
	"encoding/json"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/stacktrace"
	"github.com/google/go-cmp/cmp"
	"github.com/google/go-cmp/cmp/cmpopts"
	log "github.com/sirupsen/logrus"
	"runtime/debug"
)

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

// GetSharedWith returns the list of collections that are shared with a user
func (c *CollectionController) GetSharedWith(userID int64, sinceTime int64, app ente.App) ([]ente.Collection, error) {
	collections, err := c.CollectionRepo.GetCollectionsSharedWithUser(userID, sinceTime, app)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return collections, nil
}
