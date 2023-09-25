package pkg

import (
	debuglog "cli-go/pkg/log"
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strconv"
)

func (c *ClICtrl) fetchRemoteCollections(ctx context.Context) error {
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

func (c *ClICtrl) fetchRemoteFiles(ctx context.Context) error {
	albums, err := c.getRemoteAlbums(ctx)
	if err != nil {
		return err
	}
	for _, album := range albums {
		if album.IsDeleted {
			log.Printf("Skipping album %s as it is deleted", album.AlbumName)
			continue
		}
		lastSyncTime, lastSyncTimeErr := c.GetInt64ConfigValue(ctx, fmt.Sprintf(model.CollectionsFileSyncKeyFmt, album.ID))
		if lastSyncTimeErr != nil {
			return lastSyncTimeErr
		}
		isFirstSync := lastSyncTime == 0
		for {
			if lastSyncTime == album.LastUpdatedAt {
				break
			}
			files, hasMore, err := c.Client.GetFiles(ctx, album.ID, lastSyncTime)
			if err != nil {
				return err
			}
			maxUpdated := lastSyncTime
			for _, file := range files {
				if file.UpdationTime > maxUpdated {
					maxUpdated = file.UpdationTime
				}
				if isFirstSync && file.IsDeleted {
					// on first sync, no need to sync delete markers
					continue
				}
				fileJson := encoding.MustMarshalJSON(file)
				putErr := c.PutValue(ctx, model.RemoteFiles, []byte(strconv.FormatInt(file.ID, 10)), fileJson)
				if putErr != nil {
					return putErr
				}
			}
			if !hasMore {
				maxUpdated = album.LastUpdatedAt
			}
			if maxUpdated > lastSyncTime || !hasMore {
				err = c.PutConfigValue(ctx, fmt.Sprintf(model.CollectionsFileSyncKeyFmt, album.ID), []byte(strconv.FormatInt(maxUpdated, 10)))
				if err != nil {
					return fmt.Errorf("failed to update last sync time: %s", err)
				} else {
					lastSyncTime = maxUpdated
				}
			}
		}
	}
	return nil
}
func (c *ClICtrl) getRemoteAlbums(ctx context.Context) ([]model.Album, error) {
	albums := make([]model.Album, 0)
	albumBytes, err := c.GetAllValues(ctx, model.RemoteAlbums)
	if err != nil {
		return nil, err
	}
	for _, albumJson := range albumBytes {
		album := model.Album{}
		err = json.Unmarshal(albumJson, &album)
		if err != nil {
			return nil, err
		}
		albums = append(albums, album)
	}
	return albums, nil
}
