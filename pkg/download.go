package pkg

import (
	"cli-go/pkg/model"
	"context"
	"encoding/json"
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

func (c *ClICtrl) getRemoteFiles(ctx context.Context) ([]model.PhotoFile, error) {
	files := make([]model.PhotoFile, 0)
	fileBytes, err := c.GetAllValues(ctx, model.RemoteFiles)
	if err != nil {
		return nil, err
	}
	for _, fileJson := range fileBytes {
		file := model.PhotoFile{}
		err = json.Unmarshal(fileJson, &file)
		if err != nil {
			return nil, err
		}
		files = append(files, file)
	}
	return files, nil
}
