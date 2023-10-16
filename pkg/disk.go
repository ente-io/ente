package pkg

import (
	"cli-go/pkg/model"
	"cli-go/pkg/model/export"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
)

const (
	albumMetaFile   = "album_meta.json"
	albumMetaFolder = ".meta"
)

type albumDiskInfo struct {
	ExportRoot string
	AlbumMeta  *export.AlbumMetadata
	// FileNames contain the name of the files at root level of the album folder
	FileNames                 *map[string]bool
	MetaFileNameToDiskFileMap *map[string]*export.DiskFileMetadata
	FileIdToDiskFileMap       *map[int64]*export.DiskFileMetadata
}

func (a *albumDiskInfo) IsFilePresent(file model.RemoteFile) bool {
	// check if file.ID is present
	_, ok := (*a.FileIdToDiskFileMap)[file.ID]
	return ok
}

func (a *albumDiskInfo) IsFileNamePresent(fileName string) bool {
	_, ok := (*a.FileNames)[fileName]
	return ok
}

func (a *albumDiskInfo) AddEntry(metadata *export.DiskFileMetadata) error {
	if _, ok := (*a.FileIdToDiskFileMap)[metadata.Info.ID]; ok {
		return errors.New("fileID already present")
	}
	if _, ok := (*a.MetaFileNameToDiskFileMap)[metadata.DiskFileName]; ok {
		return errors.New("fileName already present")
	}
	(*a.MetaFileNameToDiskFileMap)[metadata.DiskFileName] = metadata
	(*a.FileIdToDiskFileMap)[metadata.Info.ID] = metadata
	return nil
}

func (a *albumDiskInfo) IsMetaFileNamePresent(metaFileName string) bool {
	_, ok := (*a.MetaFileNameToDiskFileMap)[metaFileName]
	return ok
}

func (a *albumDiskInfo) GetDiskFile(file model.RemoteFile) *export.DiskFileMetadata {
	// check if file.ID is present
	diskFile, ok := (*a.FileIdToDiskFileMap)[file.ID]
	if !ok {
		return nil
	}
	return diskFile
}

func writeJSONToFile(filePath string, data interface{}) error {
	file, err := os.Create(filePath)
	if err != nil {
		return err
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "  ")
	return encoder.Encode(data)
}

func readJSONFromFile(filePath string, data interface{}) error {
	file, err := os.Open(filePath)
	if err != nil {
		return err
	}
	defer file.Close()

	decoder := json.NewDecoder(file)
	return decoder.Decode(data)
}

func exportHome(ctx context.Context) (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	path := fmt.Sprintf("%s/%s", homeDir, "photos")
	if _, err = os.Stat(path); os.IsNotExist(err) {
		err = os.Mkdir(path, 0755)
		if err != nil {
			return "", err
		}
	}
	return path, nil
}
