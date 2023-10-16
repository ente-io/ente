package pkg

import (
	"cli-go/pkg/model"
	"cli-go/pkg/model/export"
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
	if _, ok := (*a.MetaFileNameToDiskFileMap)[metadata.MetaFileName]; ok {
		return errors.New("fileName already present")
	}
	(*a.MetaFileNameToDiskFileMap)[metadata.MetaFileName] = metadata
	(*a.FileIdToDiskFileMap)[metadata.Info.ID] = metadata
	return nil
}

func (a *albumDiskInfo) RemoveEntry(metadata *export.DiskFileMetadata) error {
	if _, ok := (*a.FileIdToDiskFileMap)[metadata.Info.ID]; !ok {
		return errors.New("fileID not present")
	}
	if _, ok := (*a.MetaFileNameToDiskFileMap)[metadata.MetaFileName]; !ok {
		return errors.New("fileName not present")
	}
	delete(*a.MetaFileNameToDiskFileMap, metadata.MetaFileName)
	delete(*a.FileIdToDiskFileMap, metadata.Info.ID)
	for _, filename := range metadata.Info.FileNames {
		delete(*a.FileNames, filename)
	}
	return nil
}

func (a *albumDiskInfo) IsMetaFileNamePresent(metaFileName string) bool {
	_, ok := (*a.MetaFileNameToDiskFileMap)[metaFileName]
	return ok
}

func (a *albumDiskInfo) GetDiskFileMetadata(file model.RemoteFile) *export.DiskFileMetadata {
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

func validateExportDirectory(dir string) (bool, error) {
	// Check if the path exists
	fileInfo, err := os.Stat(dir)
	if err != nil {
		if os.IsNotExist(err) {
			return false, fmt.Errorf("path does not exist: %s", dir)
		}
		return false, err
	}

	// Check if the path is a directory
	if !fileInfo.IsDir() {
		return false, fmt.Errorf("path is not a directory")
	}

	// Check for write permission
	// Check for write permission by creating a temp file
	tempFile, err := os.CreateTemp(dir, "write_test_")
	if err != nil {
		return false, fmt.Errorf("write permission denied: %v", err)
	}

	// Delete temp file
	defer os.Remove(tempFile.Name())
	if err != nil {
		return false, err
	}

	return true, nil
}
