package pkg

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/ente-io/cli/pkg/model/export"
)

func TestReadFilesMetadata_readsFromMetadataDir(t *testing.T) {
	dir := t.TempDir()
	albumFolderName := "TestAlbum"
	albumPath := filepath.Join(dir, albumFolderName)
	metaPath := filepath.Join(albumPath, albumMetaFolder)
	metadataPath := filepath.Join(albumPath, metadataFolder)

	for _, p := range []string{albumPath, metaPath, metadataPath} {
		if err := os.Mkdir(p, 0755); err != nil {
			t.Fatalf("mkdir %s: %v", p, err)
		}
	}

	// write a placeholder image file at the album root so FileNames is populated
	imageFileName := "photo.jpg"
	if err := os.WriteFile(filepath.Join(albumPath, imageFileName), []byte(""), 0644); err != nil {
		t.Fatalf("write image: %v", err)
	}

	// write a sidecar JSON into metadata/
	sidecarFileName := "photo.jpg.json"
	sidecar := export.DiskFileMetadata{
		Title:            "photo.jpg",
		CreationTime:     time.Now(),
		ModificationTime: time.Now(),
		Info: &export.Info{
			ID:        42,
			OwnerID:   1,
			FileNames: []string{imageFileName},
		},
	}
	sidecarBytes, err := json.Marshal(sidecar)
	if err != nil {
		t.Fatalf("marshal sidecar: %v", err)
	}
	if err := os.WriteFile(filepath.Join(metadataPath, sidecarFileName), sidecarBytes, 0644); err != nil {
		t.Fatalf("write sidecar: %v", err)
	}

	diskInfo, err := readFilesMetadata(dir, &export.AlbumMetadata{
		ID:         1,
		FolderName: albumFolderName,
		AlbumName:  "TestAlbum",
	})
	if err != nil {
		t.Fatalf("readFilesMetadata() error = %v", err)
	}

	if _, ok := (*diskInfo.FileIdToDiskFileMap)[42]; !ok {
		t.Errorf("file ID 42 not found in FileIdToDiskFileMap")
	}
	if _, ok := (*diskInfo.MetaFileNameToDiskFileMap)[strings.ToLower(sidecarFileName)]; !ok {
		t.Errorf("%q not found in MetaFileNameToDiskFileMap", sidecarFileName)
	}
	if _, ok := (*diskInfo.FileNames)[strings.ToLower(imageFileName)]; !ok {
		t.Errorf("%q not found in FileNames", imageFileName)
	}
}

func TestReadFilesMetadata_failsWithoutMetadataDir(t *testing.T) {
	dir := t.TempDir()
	albumFolderName := "TestAlbum"
	albumPath := filepath.Join(dir, albumFolderName)
	metaPath := filepath.Join(albumPath, albumMetaFolder)

	// create album and .meta but NOT metadata/
	for _, p := range []string{albumPath, metaPath} {
		if err := os.Mkdir(p, 0755); err != nil {
			t.Fatalf("mkdir %s: %v", p, err)
		}
	}

	_, err := readFilesMetadata(dir, &export.AlbumMetadata{
		ID:         1,
		FolderName: albumFolderName,
		AlbumName:  "TestAlbum",
	})
	if err == nil {
		t.Error("expected error when metadata/ dir is absent, got nil")
	}
}

func TestMigrateMetaToMetadataDir(t *testing.T) {
	dir := t.TempDir()
	metaPath := filepath.Join(dir, albumMetaFolder)
	metadataPath := filepath.Join(dir, metadataFolder)

	if err := os.Mkdir(metaPath, 0755); err != nil {
		t.Fatalf("mkdir .meta: %v", err)
	}

	// write album_meta.json (should stay in .meta/) and two sidecars (should move)
	files := map[string]string{
		albumMetaFile: `{"id":1}`,
		"photo.jpg.json":  `{"title":"photo.jpg"}`,
		"video.mp4.json":  `{"title":"video.mp4"}`,
	}
	for name, content := range files {
		if err := os.WriteFile(filepath.Join(metaPath, name), []byte(content), 0644); err != nil {
			t.Fatalf("write %s: %v", name, err)
		}
	}

	if err := migrateMetaToMetadataDir(dir); err != nil {
		t.Fatalf("migrateMetaToMetadataDir() error = %v", err)
	}

	// album_meta.json must remain in .meta/
	if _, err := os.Stat(filepath.Join(metaPath, albumMetaFile)); err != nil {
		t.Errorf("%s missing from .meta/: %v", albumMetaFile, err)
	}

	// sidecars must be in metadata/ and gone from .meta/
	for _, name := range []string{"photo.jpg.json", "video.mp4.json"} {
		if _, err := os.Stat(filepath.Join(metadataPath, name)); err != nil {
			t.Errorf("%s missing from metadata/: %v", name, err)
		}
		if _, err := os.Stat(filepath.Join(metaPath, name)); err == nil {
			t.Errorf("%s still present in .meta/ after migration", name)
		}
	}
}
