package pkg

import (
	"cli-go/pkg/mapper"
	"cli-go/pkg/model"
	"cli-go/pkg/model/export"
	"cli-go/utils"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"
)

func (c *ClICtrl) syncFiles(ctx context.Context) error {
	log.Printf("Starting sync files")
	exportRoot, err := exportHome(ctx)
	if err != nil {
		return err
	}
	_, albumIDToMetaMap, err := readFolderMetadata(exportRoot)
	if err != nil {
		return err
	}
	entries, err := c.getRemoteAlbumEntries(ctx)
	if err != nil {
		return err
	}
	log.Println("total entries", len(entries))
	model.SortAlbumFileEntry(entries)
	defer utils.TimeTrack(time.Now(), "process_files")
	var albumDiskInfo *albumDiskInfo
	for i, entry := range entries {
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
			putErr := c.DeleteValue(ctx, model.RemoteAlbumEntries, []byte(fmt.Sprintf("%d:%d", entry.AlbumID, entry.FileID)))
			if putErr != nil {
				return putErr
			}
			continue
		}
		fmt.Println("entry", i, albumInfo.AlbumName, entry.FileID, entry.SyncedLocally)
		if albumDiskInfo == nil || albumDiskInfo.AlbumMeta.ID != albumInfo.ID {
			albumDiskInfo, err = readFilesMetadata(exportRoot, albumInfo)
			if err != nil {
				return err
			}
		}
		fileBytes, err := c.GetValue(ctx, model.RemoteFiles, []byte(fmt.Sprintf("%d", entry.FileID)))
		if err != nil {
			return err
		}
		if fileBytes != nil {
			var existingEntry *model.RemoteFile
			err = json.Unmarshal(fileBytes, &existingEntry)
			if err != nil {
				return err
			}
			err = c.downloadEntry(ctx, albumDiskInfo, *existingEntry, entry)
			if err != nil {
				return err
			}
		} else {
			log.Fatalf("remoteFile %d not found in remoteFiles", entry.FileID)
		}
	}
	return nil
}

func (c *ClICtrl) downloadEntry(ctx context.Context,
	diskInfo *albumDiskInfo,
	file model.RemoteFile,
	albumEntry *model.AlbumFileEntry) error {
	if !diskInfo.AlbumMeta.IsDeleted && albumEntry.IsDeleted {
		albumEntry.IsDeleted = true
		diskFile := diskInfo.GetDiskFile(file)
		if diskFile != nil {
			// remove the file from disk
			log.Printf("Removing file %s from disk", diskFile.DiskFileName)
			err := os.Remove(filepath.Join(diskInfo.ExportRoot, diskInfo.AlbumMeta.FolderName, ".meta", diskFile.DiskFileName))
			if err != nil {
				return err
			}
		}
		putErr := c.DeleteValue(ctx, model.RemoteAlbumEntries, []byte(fmt.Sprintf("%d:%d", albumEntry.AlbumID, albumEntry.FileID)))
		if putErr != nil {
			return putErr
		}
	}
	if !diskInfo.IsFilePresent(file) {
		fileDiskMetadata := mapper.MapRemoteFileToDiskMetadata(file)
		potentialDiskFileName := fileDiskMetadata.Title + "." + "json"
		count := 1
		for diskInfo.IsMetaFileNamePresent(potentialDiskFileName) {
			// separate the file name and extension
			potentialDiskFileName = fmt.Sprintf("%s_%d.json", fileDiskMetadata.Title, count)
			count++
			if !diskInfo.IsMetaFileNamePresent(potentialDiskFileName) {
				break
			}
		}
		err := writeJSONToFile(filepath.Join(diskInfo.ExportRoot, diskInfo.AlbumMeta.FolderName, ".meta", potentialDiskFileName), fileDiskMetadata)
		if err != nil {
			return err
		}

	}
	return nil
}

// readFolderMetadata reads the metadata of the files in the given path
// For disk export, a particular albums files are stored in a folder named after the album.
// Inside the folder, the files are stored at top level and its metadata is stored in a .meta folder
func readFilesMetadata(home string, albumMeta *export.AlbumMetadata) (*albumDiskInfo, error) {
	albumMetadataFolder := filepath.Join(home, albumMeta.FolderName, albumMetaFolder)
	albumPath := filepath.Join(home, albumMeta.FolderName)
	// verify the both the album folder and the .meta folder exist
	if _, err := os.Stat(albumMetadataFolder); err != nil {
		return nil, err
	}
	if _, err := os.Stat(albumPath); err != nil {
		return nil, err
	}
	result := make(map[string]*export.DiskFileMetadata)
	//fileNameToFileName := make(map[string]*export.DiskFileMetadata)
	fileIdToMetadata := make(map[int64]*export.DiskFileMetadata)
	claimedFileName := make(map[string]bool)
	// Read the top-level directories in the given path
	albumFileEntries, err := os.ReadDir(albumPath)
	if err != nil {
		return nil, err
	}
	for _, entry := range albumFileEntries {
		if !entry.IsDir() {
			claimedFileName[entry.Name()] = true
		}
	}
	metaEntries, err := os.ReadDir(albumMetadataFolder)
	if err != nil {
		return nil, err
	}
	for _, entry := range metaEntries {
		if !entry.IsDir() {
			fileName := entry.Name()
			if fileName == albumMetaFile {
				continue
			}
			if !strings.HasSuffix(fileName, ".json") {
				log.Printf("Skipping file %s as it is not a JSON file", fileName)
				continue
			}
			fileMetadataPath := filepath.Join(albumMetadataFolder, fileName)
			// Initialize as nil, will remain nil if JSON file is not found or not readable
			result[fileName] = nil
			// Read the JSON file if it exists
			var metaData export.DiskFileMetadata
			metaDataBytes, err := os.ReadFile(fileMetadataPath)
			if err != nil {
				continue // Skip this entry if reading fails
			}
			if err := json.Unmarshal(metaDataBytes, &metaData); err == nil {
				metaData.DiskFileName = fileName
				result[fileName] = &metaData
				fileIdToMetadata[metaData.Info.ID] = &metaData
			}
		}
	}
	return &albumDiskInfo{
		ExportRoot:                home,
		AlbumMeta:                 albumMeta,
		FileNames:                 &claimedFileName,
		MetaFileNameToDiskFileMap: &result,
		FileIdToDiskFileMap:       &fileIdToMetadata,
	}, nil
}
