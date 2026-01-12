package takeout

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

// ParsedMetadata represents the metadata extracted from a Google Takeout JSON file
type ParsedMetadata struct {
	CreationTime     *int64    `json:"creationTime,omitempty"`
	ModificationTime *int64    `json:"modificationTime,omitempty"`
	Location         *Location `json:"location,omitempty"`
	Description      string    `json:"description,omitempty"`
}

// Location represents GPS coordinates
type Location struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

// takeoutJSON represents the structure of a Google Takeout metadata JSON file
type takeoutJSON struct {
	PhotoTakenTime   *timestampField `json:"photoTakenTime,omitempty"`
	CreationTime     *timestampField `json:"creationTime,omitempty"`
	ModificationTime *timestampField `json:"modificationTime,omitempty"`
	GeoData          *geoField       `json:"geoData,omitempty"`
	GeoDataExif      *geoField       `json:"geoDataExif,omitempty"`
	Description      string          `json:"description,omitempty"`
}

type timestampField struct {
	Timestamp interface{} `json:"timestamp"` // Can be string or number
}

type geoField struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

// ParseMetadataJSON reads and parses a Google Takeout JSON metadata file
func ParseMetadataJSON(jsonPath string) (*ParsedMetadata, error) {
	data, err := os.ReadFile(jsonPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read JSON file: %w", err)
	}

	var tj takeoutJSON
	if err := json.Unmarshal(data, &tj); err != nil {
		return nil, fmt.Errorf("failed to parse JSON: %w", err)
	}

	parsed := &ParsedMetadata{}

	// Parse creation time (prefer photoTakenTime over creationTime)
	if tj.PhotoTakenTime != nil {
		parsed.CreationTime = parseTimestamp(tj.PhotoTakenTime)
	} else if tj.CreationTime != nil {
		parsed.CreationTime = parseTimestamp(tj.CreationTime)
	}

	// Parse modification time
	if tj.ModificationTime != nil {
		parsed.ModificationTime = parseTimestamp(tj.ModificationTime)
	}

	// Parse location (prefer geoData over geoDataExif)
	if tj.GeoData != nil {
		parsed.Location = parseLocation(tj.GeoData)
	} else if tj.GeoDataExif != nil {
		parsed.Location = parseLocation(tj.GeoDataExif)
	}

	// Parse description (treat empty strings as nil)
	if tj.Description != "" {
		parsed.Description = tj.Description
	}

	return parsed, nil
}

// parseTimestamp converts a timestamp field to epoch microseconds
func parseTimestamp(tf *timestampField) *int64 {
	if tf == nil || tf.Timestamp == nil {
		return nil
	}

	var epochSeconds int64

	switch v := tf.Timestamp.(type) {
	case string:
		// Parse string as integer
		var parsed int64
		_, err := fmt.Sscanf(v, "%d", &parsed)
		if err != nil {
			return nil
		}
		epochSeconds = parsed
	case float64:
		epochSeconds = int64(v)
	case int64:
		epochSeconds = v
	default:
		return nil
	}

	// Convert seconds to microseconds
	epochMicros := epochSeconds * 1e6
	return &epochMicros
}

// parseLocation converts a geo field to a Location if valid
func parseLocation(gf *geoField) *Location {
	if gf == nil {
		return nil
	}

	// Google puts (0,0) for missing data
	if gf.Latitude == 0 && gf.Longitude == 0 {
		return nil
	}

	return &Location{
		Latitude:  gf.Latitude,
		Longitude: gf.Longitude,
	}
}

// MatchMetadataForFile attempts to find matching metadata for a given file
// This implements the complex matching logic used in the web client
func MatchMetadataForFile(
	fileName string,
	collectionID int,
	pathPrefix string,
	metadataMap map[string]*ParsedMetadata,
) *ParsedMetadata {
	// Helper to create map key
	makeKey := func(fn string) string {
		return fmt.Sprintf("%s-%d-%s", pathPrefix, collectionID, fn)
	}

	// Split filename into name and extension
	name := strings.TrimSuffix(fileName, filepath.Ext(fileName))
	ext := filepath.Ext(fileName)

	// Extract and remove numbered suffix like (1), (2), etc.
	numberedSuffixRegex := regexp.MustCompile(`\(\d+\)$`)
	numberedSuffix := ""
	if match := numberedSuffixRegex.FindString(name); match != "" {
		name = strings.TrimSuffix(name, match)
		numberedSuffix = match
	}

	// Remove -edited suffix if present
	const editedSuffix = "-edited"
	if strings.HasSuffix(name, editedSuffix) {
		name = strings.TrimSuffix(name, editedSuffix)
	}

	// Try 1: Direct match with base filename + numbered suffix
	baseFileName := name + ext
	key := makeKey(baseFileName + numberedSuffix)
	if metadata, ok := metadataMap[key]; ok {
		return metadata
	}

	// Try 2: Match with file name clipped to 46 characters
	// Google Photos clips long filenames in the metadata JSON
	const maxGoogleFileNameLength = 46
	clippedName := baseFileName + numberedSuffix
	if len(clippedName) > maxGoogleFileNameLength {
		clippedName = clippedName[:maxGoogleFileNameLength]
		key = makeKey(clippedName)
		if metadata, ok := metadataMap[key]; ok {
			return metadata
		}
	}

	// Try 3: Match with .supplemental-metadata suffix
	// Newer Takeout exports add this suffix to metadata files
	const supplSuffix = ".supplemental-metadata"
	supplFileName := name + ext + supplSuffix

	// If the filename gets too long, it gets clipped
	if len(supplFileName) > maxGoogleFileNameLength {
		supplFileName = supplFileName[:maxGoogleFileNameLength]
	}

	key = makeKey(supplFileName + numberedSuffix)
	if metadata, ok := metadataMap[key]; ok {
		return metadata
	}

	return nil
}

// MetadataJSONMapKeyForJSON creates a map key for a JSON metadata file
func MetadataJSONMapKeyForJSON(pathPrefix string, collectionID int, jsonFileName string) string {
	// Remove .json extension
	fileName := strings.TrimSuffix(jsonFileName, ".json")
	return fmt.Sprintf("%s-%d-%s", pathPrefix, collectionID, fileName)
}
