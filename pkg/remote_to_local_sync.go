package pkg

import (
	"context"
	"fmt"
	"log"
	"os"
)

// CreateLocalFolderForRemoteAlbums will get all the remote albums and create a local folder for each of them
func (c *ClICtrl) CreateLocalFolderForRemoteAlbums(ctx context.Context) error {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return err
	}
	path := fmt.Sprintf("%s/%s", homeDir, "photos")
	if _, err := os.Stat(path); os.IsNotExist(err) {
		err = os.Mkdir(path, 0755)
		if err != nil {
			return err
		}
	}
	albums, err := c.getRemoteAlbums(ctx)
	if err != nil {
		return err
	}
	for _, album := range albums {
		if album.IsDeleted {
			continue
		}
		albumPath := path + "/" + album.AlbumName
		// create the folder if it doesn't exist
		if _, err := os.Stat(albumPath); os.IsNotExist(err) {
			err = os.Mkdir(albumPath, 0755)
			if err != nil {
				return err
			}
		} else {
			log.Printf("Folder %s already exists", albumPath)
		}
	}
	return nil
}
