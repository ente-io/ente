package takeout

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

// FileInfo represents information about a file to be imported
type FileInfo struct {
	Path     string
	FileName string
	IsJSON   bool
}

// ScanResult contains the results of scanning a Google Takeout folder
type ScanResult struct {
	MediaFiles  []FileInfo
	MetadataMap map[string]*ParsedMetadata
	Errors      []error
}

// ScanFolder walks through a Google Takeout folder and separates media files from JSON metadata
func ScanFolder(folderPath string, collectionID int) (*ScanResult, error) {
	if _, err := os.Stat(folderPath); os.IsNotExist(err) {
		return nil, fmt.Errorf("folder does not exist: %s", folderPath)
	}

	result := &ScanResult{
		MediaFiles:  make([]FileInfo, 0),
		MetadataMap: make(map[string]*ParsedMetadata),
		Errors:      make([]error, 0),
	}

	err := filepath.Walk(folderPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			result.Errors = append(result.Errors, fmt.Errorf("error accessing %s: %w", path, err))
			return nil // Continue walking
		}

		// Skip directories
		if info.IsDir() {
			return nil
		}

		// Get relative path from folder root for pathPrefix
		relPath, err := filepath.Rel(folderPath, path)
		if err != nil {
			result.Errors = append(result.Errors, fmt.Errorf("error getting relative path for %s: %w", path, err))
			return nil
		}

		fileName := filepath.Base(path)
		pathPrefix := filepath.Dir(relPath)
		if pathPrefix == "." {
			pathPrefix = ""
		}

		// Check if it's a JSON metadata file
		if strings.HasSuffix(strings.ToLower(fileName), ".json") {
			// Parse the JSON metadata
			metadata, err := ParseMetadataJSON(path)
			if err != nil {
				result.Errors = append(result.Errors, fmt.Errorf("error parsing JSON %s: %w", path, err))
				return nil
			}

			// Add to metadata map
			key := MetadataJSONMapKeyForJSON(pathPrefix, collectionID, fileName)
			result.MetadataMap[key] = metadata

			// Also track as a file info (but marked as JSON)
			result.MediaFiles = append(result.MediaFiles, FileInfo{
				Path:     path,
				FileName: fileName,
				IsJSON:   true,
			})
		} else {
			// It's a media file
			result.MediaFiles = append(result.MediaFiles, FileInfo{
				Path:     path,
				FileName: fileName,
				IsJSON:   false,
			})
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("error walking folder: %w", err)
	}

	return result, nil
}

// GetMediaFiles filters the scanned files to only return non-JSON media files
func (sr *ScanResult) GetMediaFiles() []FileInfo {
	mediaFiles := make([]FileInfo, 0, len(sr.MediaFiles))
	for _, fi := range sr.MediaFiles {
		if !fi.IsJSON {
			mediaFiles = append(mediaFiles, fi)
		}
	}
	return mediaFiles
}

// GetMetadataForFile retrieves metadata for a given media file
func (sr *ScanResult) GetMetadataForFile(fileName string, collectionID int, pathPrefix string) *ParsedMetadata {
	return MatchMetadataForFile(fileName, collectionID, pathPrefix, sr.MetadataMap)
}

// Stats returns statistics about the scan
type ScanStats struct {
	TotalFiles        int
	MediaFiles        int
	JSONFiles         int
	FilesWithMetadata int
	Errors            int
}

// GetStats computes statistics about the scan result
func (sr *ScanResult) GetStats(collectionID int) ScanStats {
	mediaFiles := sr.GetMediaFiles()
	filesWithMetadata := 0

	for _, mf := range mediaFiles {
		// Extract path prefix
		pathPrefix := ""
		if idx := strings.LastIndex(mf.Path, string(filepath.Separator)); idx != -1 {
			if dirPath := filepath.Dir(mf.Path); dirPath != "." {
				pathPrefix = filepath.Base(dirPath)
			}
		}

		if sr.GetMetadataForFile(mf.FileName, collectionID, pathPrefix) != nil {
			filesWithMetadata++
		}
	}

	return ScanStats{
		TotalFiles:        len(sr.MediaFiles),
		MediaFiles:        len(mediaFiles),
		JSONFiles:         len(sr.MediaFiles) - len(mediaFiles),
		FilesWithMetadata: filesWithMetadata,
		Errors:            len(sr.Errors),
	}
}
