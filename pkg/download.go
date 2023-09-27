package pkg

import (
	"context"
	"fmt"
	"log"
	"os"
)

func (c *ClICtrl) initiateDownload(ctx context.Context) error {
	files, err := c.getRemoteFiles(ctx)
	if err != nil {
		return err
	}
	dir, err := os.MkdirTemp("", "photos-download")
	if err != nil {
		return err
	}
	for _, file := range files {
		downloadPath := fmt.Sprintf("%s/%d", dir, file.ID)
		log.Printf("Downloading file %d to %s", file.ID, downloadPath)
		//err = c.Client.DownloadFile(ctx, file.ID, downloadPath)
		//if err != nil {
		//	return err
		//}
	}
	return nil
}
