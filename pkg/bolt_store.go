package pkg

import (
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
	"fmt"
)

func boltAEKey(entry *model.AlbumFileEntry) []byte {
	return []byte(fmt.Sprintf("%d:%d", entry.AlbumID, entry.FileID))
}

func (c *ClICtrl) DeleteAlbumEntry(ctx context.Context, entry *model.AlbumFileEntry) error {
	return c.DeleteValue(ctx, model.RemoteAlbumEntries, boltAEKey(entry))
}

func (c *ClICtrl) UpsertAlbumEntry(ctx context.Context, entry *model.AlbumFileEntry) error {
	return c.PutValue(ctx, model.RemoteAlbumEntries, boltAEKey(entry), encoding.MustMarshalJSON(entry))
}
