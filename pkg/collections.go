package pkg

import (
	debuglog "cli-go/pkg/log"
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
	"fmt"
	"strconv"
)

func (c *ClICtrl) fetchRemoteCollections(ctx context.Context, info model.Account) error {
	lastSyncTime, err2 := c.GetInt64ConfigValue(ctx, model.CollectionsSyncKey)
	if err2 != nil {
		return err2
	}
	collections, err := c.Client.GetCollections(ctx, lastSyncTime)
	if err != nil {
		return fmt.Errorf("failed to get collections: %s", err)
	}
	maxUpdated := lastSyncTime
	for _, collection := range collections {
		if lastSyncTime == 0 && collection.IsDeleted {
			continue
		}
		album, mapErr := c.mapCollectionToAlbum(ctx, collection)
		if mapErr != nil {
			return mapErr
		}
		if album.LastUpdatedAt > maxUpdated {
			maxUpdated = album.LastUpdatedAt
		}
		albumJson := encoding.MustMarshalJSON(album)
		putErr := c.PutValue(ctx, model.RemoteAlbums, []byte(strconv.FormatInt(album.ID, 10)), albumJson)
		if putErr != nil {
			return putErr
		}
		debuglog.PrintAlbum(album)
	}
	if maxUpdated > lastSyncTime {
		err = c.PutConfigValue(ctx, model.CollectionsSyncKey, []byte(strconv.FormatInt(maxUpdated, 10)))
		if err != nil {
			return fmt.Errorf("failed to update last sync time: %s", err)
		}
	}
	return nil
}
