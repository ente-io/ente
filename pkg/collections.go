package pkg

import (
	debuglog "cli-go/pkg/log"
	"cli-go/pkg/model"
	"context"
	"fmt"
)

func (c *ClICtrl) syncRemoteCollections(ctx context.Context, info model.Account) error {
	collections, err := c.Client.GetCollections(ctx, 0)
	if err != nil {
		return fmt.Errorf("failed to get collections: %s", err)
	}

	for _, collection := range collections {
		album, err2 := c.mapCollectionToAlbum(ctx, collection)
		if err2 != nil {
			return err2
		}
		debuglog.PrintAlbum(album)
	}
	return nil
}
