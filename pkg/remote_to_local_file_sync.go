package pkg

import (
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
	"encoding/json"
	"fmt"
	"log"
)

func (c *ClICtrl) syncFiles(ctx context.Context) error {
	home, err := exportHome(ctx)
	if err != nil {
		return err
	}
	_, albumIDToMetaMap, err := readFolderMetadata(home)
	if err != nil {
		return err
	}
	entries, err := c.getRemoteAlbumEntries(ctx)
	if err != nil {
		return err
	}
	for _, entry := range entries {
		if entry.SyncedLocally {
			continue
		}
		albumInfo, ok := albumIDToMetaMap[entry.AlbumID]
		if !ok {
			log.Printf("Album %d not found in local metadata", entry.AlbumID)
			continue
		}
		if albumInfo.IsDeleted {
			entry.IsDeleted = true
			albumEntryJson := encoding.MustMarshalJSON(entry)
			putErr := c.PutValue(ctx, model.RemoteAlbumEntries, []byte(fmt.Sprintf("%d:%d", entry.AlbumID, entry.FileID)), albumEntryJson)
			if putErr != nil {
				return putErr
			}
			continue
		}
		fileBytes, err := c.GetValue(ctx, model.RemoteAlbumEntries, []byte(fmt.Sprintf("%d:%d", entry.AlbumID, entry.FileID)))
		if err != nil {
			return err
		}
		if fileBytes != nil {
			var existingEntry model.RemoteFile
			err = json.Unmarshal(fileBytes, &existingEntry)
			if err != nil {
				return err
			}
			log.Printf("Should download %s into %s", existingEntry.Metadata["name"], albumInfo.FolderName)
		}
	}
	return nil
}
