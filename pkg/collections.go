package pkg

import (
	debuglog "cli-go/pkg/log"
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
	"fmt"
	"strconv"
)

func (c *ClICtrl) syncRemoteCollections(ctx context.Context, info model.Account) error {
	valueBytes, err := c.GetConfigValue(ctx, model.CollectionsSyncKey)
	if err != nil {
		return fmt.Errorf("failed to get last sync time: %s", err)
	}
	var lastSyncTime int64
	if valueBytes != nil {
		lastSyncTime, err = strconv.ParseInt(string(valueBytes), 10, 64)
		if err != nil {
			return err
		}
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
		album, err2 := c.mapCollectionToAlbum(ctx, collection)
		if err2 != nil {
			return err2
		}
		if album.LastUpdatedAt > maxUpdated {
			maxUpdated = album.LastUpdatedAt
		}
		albumJson := encoding.MustMarshalJSON(album)
		err := c.PutValue(ctx, model.RemoteAlbums, []byte(strconv.FormatInt(album.ID, 10)), albumJson)
		if err != nil {
			return err
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
