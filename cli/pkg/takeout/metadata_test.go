package takeout

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseMetadataJSON(t *testing.T) {
	tests := []struct {
		name        string
		jsonContent string
		wantErr     bool
		validate    func(*testing.T, *ParsedMetadata)
	}{
		{
			name: "Complete metadata",
			jsonContent: `{
				"photoTakenTime": {"timestamp": "1625097736"},
				"modificationTime": {"timestamp": "1625097740"},
				"geoData": {"latitude": 37.7749, "longitude": -122.4194},
				"description": "Test photo"
			}`,
			wantErr: false,
			validate: func(t *testing.T, pm *ParsedMetadata) {
				if pm.CreationTime == nil {
					t.Error("CreationTime should not be nil")
				} else if *pm.CreationTime != 1625097736000000 {
					t.Errorf("CreationTime = %d, want %d", *pm.CreationTime, 1625097736000000)
				}
				if pm.ModificationTime == nil {
					t.Error("ModificationTime should not be nil")
				}
				if pm.Location == nil {
					t.Error("Location should not be nil")
				} else {
					if pm.Location.Latitude != 37.7749 {
						t.Errorf("Latitude = %f, want %f", pm.Location.Latitude, 37.7749)
					}
				}
				if pm.Description != "Test photo" {
					t.Errorf("Description = %s, want 'Test photo'", pm.Description)
				}
			},
		},
		{
			name: "Numeric timestamp",
			jsonContent: `{
				"creationTime": {"timestamp": 1625097736}
			}`,
			wantErr: false,
			validate: func(t *testing.T, pm *ParsedMetadata) {
				if pm.CreationTime == nil {
					t.Error("CreationTime should not be nil")
				}
			},
		},
		{
			name: "Zero location ignored",
			jsonContent: `{
				"geoData": {"latitude": 0, "longitude": 0}
			}`,
			wantErr: false,
			validate: func(t *testing.T, pm *ParsedMetadata) {
				if pm.Location != nil {
					t.Error("Location should be nil for (0,0)")
				}
			},
		},
		{
			name: "Empty description ignored",
			jsonContent: `{
				"description": ""
			}`,
			wantErr: false,
			validate: func(t *testing.T, pm *ParsedMetadata) {
				if pm.Description != "" {
					t.Error("Description should be empty")
				}
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create temporary JSON file
			tmpDir := t.TempDir()
			jsonPath := filepath.Join(tmpDir, "metadata.json")
			if err := os.WriteFile(jsonPath, []byte(tt.jsonContent), 0644); err != nil {
				t.Fatalf("Failed to write test JSON: %v", err)
			}

			// Parse the metadata
			metadata, err := ParseMetadataJSON(jsonPath)
			if (err != nil) != tt.wantErr {
				t.Errorf("ParseMetadataJSON() error = %v, wantErr %v", err, tt.wantErr)
				return
			}

			if !tt.wantErr && tt.validate != nil {
				tt.validate(t, metadata)
			}
		})
	}
}

func TestMatchMetadataForFile(t *testing.T) {
	creationTime := int64(1625097736000000)
	metadata := &ParsedMetadata{
		CreationTime: &creationTime,
	}

	tests := []struct {
		name        string
		fileName    string
		setupMap    func(map[string]*ParsedMetadata)
		shouldMatch bool
	}{
		{
			name:     "Direct match",
			fileName: "IMG_1234.jpg",
			setupMap: func(m map[string]*ParsedMetadata) {
				m["prefix-0-IMG_1234.jpg"] = metadata
			},
			shouldMatch: true,
		},
		{
			name:     "Match with numbered suffix",
			fileName: "IMG_1234(1).jpg",
			setupMap: func(m map[string]*ParsedMetadata) {
				m["prefix-0-IMG_1234.jpg(1)"] = metadata
			},
			shouldMatch: true,
		},
		{
			name:     "Match with edited suffix",
			fileName: "IMG_1234-edited.jpg",
			setupMap: func(m map[string]*ParsedMetadata) {
				m["prefix-0-IMG_1234.jpg"] = metadata
			},
			shouldMatch: true,
		},
		{
			name:     "Match with long filename (clipped)",
			fileName: "Very_long_filename_that_exceeds_46_characters_limit.jpg",
			setupMap: func(m map[string]*ParsedMetadata) {
				// Google clips at 46 chars - this is the first 46 chars of the full filename
				m["prefix-0-Very_long_filename_that_exceeds_46_characters_"] = metadata
			},
			shouldMatch: true,
		},
		{
			name:     "Match with supplemental-metadata suffix",
			fileName: "IMG_1234.jpg",
			setupMap: func(m map[string]*ParsedMetadata) {
				m["prefix-0-IMG_1234.jpg.supplemental-metadata"] = metadata
			},
			shouldMatch: true,
		},
		{
			name:     "No match",
			fileName: "IMG_9999.jpg",
			setupMap: func(m map[string]*ParsedMetadata) {
				m["prefix-0-IMG_1234.jpg"] = metadata
			},
			shouldMatch: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			testMap := make(map[string]*ParsedMetadata)
			tt.setupMap(testMap)

			result := MatchMetadataForFile(tt.fileName, 0, "prefix", testMap)

			if tt.shouldMatch && result == nil {
				t.Error("Expected to find metadata, but got nil")
			}
			if !tt.shouldMatch && result != nil {
				t.Error("Expected no metadata match, but got a result")
			}
		})
	}
}

func TestMetadataJSONMapKeyForJSON(t *testing.T) {
	tests := []struct {
		name         string
		pathPrefix   string
		collectionID int
		jsonFileName string
		want         string
	}{
		{
			name:         "Simple JSON file",
			pathPrefix:   "Photos",
			collectionID: 123,
			jsonFileName: "IMG_1234.jpg.json",
			want:         "Photos-123-IMG_1234.jpg",
		},
		{
			name:         "JSON with supplemental-metadata",
			pathPrefix:   "Photos",
			collectionID: 123,
			jsonFileName: "IMG_1234.jpg.supplemental-metadata.json",
			want:         "Photos-123-IMG_1234.jpg.supplemental-metadata",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := MetadataJSONMapKeyForJSON(tt.pathPrefix, tt.collectionID, tt.jsonFileName)
			if got != tt.want {
				t.Errorf("MetadataJSONMapKeyForJSON() = %v, want %v", got, tt.want)
			}
		})
	}
}
