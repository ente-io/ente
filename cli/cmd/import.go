package cmd

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"path/filepath"
	"strings"

	"github.com/ente-io/cli/internal/api"
	eCrypto "github.com/ente-io/cli/internal/crypto"
	"github.com/ente-io/cli/pkg/takeout"
	"github.com/ente-io/cli/pkg/uploader"
	"github.com/spf13/cobra"
)

// debugMode controls verbose debug output
var debugMode bool

// debugLog prints a message only if debug mode is enabled
func debugLog(format string, args ...interface{}) {
	if debugMode {
		log.Printf("DEBUG: "+format, args...)
	}
}

// importCmd represents the import command
var importCmd = &cobra.Command{
	Use:   "import-google-takeout-folder <folder-path> [album-name]",
	Short: "Import a Google Takeout folder with metadata preservation",
	Long: `Import photos and videos from a Google Takeout export folder.

This command scans the folder for media files and their associated JSON metadata
files (created by Google Takeout), then uploads them to Ente while preserving
timestamps, location data, and descriptions.

Examples:
  # Import to a new album
  ente import-google-takeout-folder /path/to/takeout "My Photos"
  
  # Import using --album flag
  ente import-google-takeout-folder /path/to/takeout --album "Vacation 2023"
  
  # Dry run to see what would be imported
  ente import-google-takeout-folder /path/to/takeout --dry-run`,
	Args: cobra.RangeArgs(1, 2),
	Run: func(cmd *cobra.Command, args []string) {
		folderPath := args[0]

		// Get album name from positional arg or flag
		albumName, _ := cmd.Flags().GetString("album")
		if len(args) > 1 && albumName == "" {
			albumName = args[1]
		}
		if albumName == "" {
			albumName = filepath.Base(folderPath)
			log.Printf("No album name specified, using folder name: %s\n", albumName)
		}

		// Get flags
		dryRun, _ := cmd.Flags().GetBool("dry-run")
		skipMetadata, _ := cmd.Flags().GetBool("skip-metadata")

		// Run the import
		err := runImport(folderPath, albumName, dryRun, skipMetadata)
		if err != nil {
			log.Fatalf("Import failed: %v\n", err)
		}
	},
}

func init() {
	rootCmd.AddCommand(importCmd)

	// Add flags
	importCmd.Flags().String("album", "", "Album name (alternative to positional argument)")
	importCmd.Flags().Bool("dry-run", false, "Scan and preview what would be imported without uploading")
	importCmd.Flags().Bool("skip-metadata", false, "Import without parsing JSON metadata sidecars")
	importCmd.Flags().BoolVarP(&debugMode, "debug", "d", false, "Enable debug output")
}

func runImport(folderPath, albumName string, dryRun, skipMetadata bool) error {
	log.Printf("Scanning Google Takeout folder: %s\n", folderPath)

	// Scan the folder
	const dummyCollectionID = 0
	scanResult, err := takeout.ScanFolder(folderPath, dummyCollectionID)
	if err != nil {
		return fmt.Errorf("failed to scan folder: %w", err)
	}

	// Show errors encountered during scan
	if len(scanResult.Errors) > 0 {
		log.Printf("Encountered %d errors during scan:\n", len(scanResult.Errors))
		for i, err := range scanResult.Errors {
			if i < 5 {
				log.Printf("  - %v\n", err)
			}
		}
		if len(scanResult.Errors) > 5 {
			log.Printf("  ... and %d more errors\n", len(scanResult.Errors)-5)
		}
	}

	// Get stats
	stats := scanResult.GetStats(dummyCollectionID)
	log.Printf("\nScan complete:\n")
	log.Printf("  Total files: %d\n", stats.TotalFiles)
	log.Printf("  Media files: %d\n", stats.MediaFiles)
	log.Printf("  JSON files: %d\n", stats.JSONFiles)
	if !skipMetadata {
		log.Printf("  Media files with metadata: %d\n", stats.FilesWithMetadata)
		log.Printf("  Media files without metadata: %d\n", stats.MediaFiles-stats.FilesWithMetadata)
	}

	if dryRun {
		log.Println("\nDry run mode - no files will be uploaded")

		// Show a preview of files
		mediaFiles := scanResult.GetMediaFiles()
		log.Printf("\nPreview of files to import (showing first 10):\n")
		for i, fi := range mediaFiles {
			if i >= 10 {
				log.Printf("  ... and %d more files\n", len(mediaFiles)-10)
				break
			}

			// Try to get metadata for this file
			pathPrefix := ""
			if dir := filepath.Dir(fi.Path); dir != "." {
				pathPrefix = filepath.Base(dir)
			}

			if !skipMetadata {
				if metadata := scanResult.GetMetadataForFile(fi.FileName, dummyCollectionID, pathPrefix); metadata != nil {
					log.Printf("  - %s (has metadata)\n", fi.FileName)
				} else {
					log.Printf("  - %s (no metadata)\n", fi.FileName)
				}
			} else {
				log.Printf("  - %s\n", fi.FileName)
			}
		}

		return nil
	}

	// Actual upload using controller
	log.Printf("\nStarting upload to album: %s\n", albumName)

	// Get active account
	accounts, err := ctrl.GetAccounts(context.Background())
	if err != nil {
		return fmt.Errorf("failed to get accounts: %w", err)
	}
	if len(accounts) == 0 {
		return fmt.Errorf("no active account found. Please add an account first using 'ente account add'")
	}

	account := accounts[0]

	// Load secrets and add token
	secretInfo, err := ctrl.KeyHolder.LoadSecrets(account)
	if err != nil {
		return fmt.Errorf("failed to load account secrets: %w", err)
	}
	ctrl.Client.AddToken(account.AccountKey(), base64.URLEncoding.EncodeToString(secretInfo.Token))

	// Build context with account info
	ctx := context.Background()
	ctx = context.WithValue(ctx, "app", string(account.App))
	ctx = context.WithValue(ctx, "account_key", account.AccountKey())
	ctx = context.WithValue(ctx, "user_id", account.UserID)

	// Find album by name (albums must be created in web UI first)
	log.Println("Finding album...")
	collections, err := ctrl.Client.GetCollections(ctx, 0)
	if err != nil {
		return fmt.Errorf("failed to get collections: %w", err)
	}

	// Decrypt collection names to match against album name
	for i := range collections {
		collKey, err := ctrl.KeyHolder.GetCollectionKey(ctx, collections[i])
		if err == nil && collections[i].EncryptedName != "" {
			decrName, err := eCrypto.SecretBoxOpenBase64(
				collections[i].EncryptedName,
				collections[i].NameDecryptionNonce,
				collKey)
			if err == nil {
				collections[i].Name = string(decrName)
			}
		}
	}

	debugLog("Found %d collections", len(collections))
	for i, col := range collections {
		debugLog("  [%d] Name: '%s' (ID: %d)", i, col.Name, col.ID)
	}

	var collection *api.Collection
	for i := range collections {
		if collections[i].Name == albumName && !collections[i].IsDeleted {
			collection = &collections[i]
			log.Printf("Found existing album: %s (ID: %d)\n", albumName, collection.ID)
			break
		}
	}

	if collection == nil {
		return fmt.Errorf("album '%s' not found. Please create it in the web app first", albumName)
	}

	// Decrypt collection key
	log.Println("Decrypting collection key...")
	collectionKey, err := ctrl.KeyHolder.GetCollectionKey(ctx, *collection)
	if err != nil {
		return fmt.Errorf("failed to decrypt collection key: %w", err)
	}

	session := uploader.NewUploadSession(ctrl.Client, collection)

	// Fetch existing files to build a duplicate detection map
	log.Println("Fetching existing files for duplicate detection...")
	existingFiles, err := fetchExistingFilesMap(ctx, ctrl.Client, collection.ID, collectionKey, session)
	if err != nil {
		debugLog("Failed to fetch existing files (will proceed without duplicate detection): %v", err)
		existingFiles = make(map[string]bool)
	}

	// Upload each media file
	mediaFiles := scanResult.GetMediaFiles()
	log.Printf("\nUploading %d files...\n", len(mediaFiles))

	successCount := 0
	errorCount := 0

	for i, fi := range mediaFiles {
		log.Printf("[%d/%d] Processing %s...", i+1, len(mediaFiles), fi.FileName)

		// Get Takeout metadata if available
		pathPrefix := ""
		if dir := filepath.Dir(fi.Path); dir != "." {
			pathRelative, _ := filepath.Rel(folderPath, dir)
			pathPrefix = pathRelative
		}

		var metadata *uploader.SimpleFileMetadata
		if !skipMetadata {
			if takeoutMeta := scanResult.GetMetadataForFile(fi.FileName, int(collection.ID), pathPrefix); takeoutMeta != nil {
				metadata = &uploader.SimpleFileMetadata{}
				if takeoutMeta.CreationTime != nil {
					metadata.CreationTime = *takeoutMeta.CreationTime
				}
				if takeoutMeta.ModificationTime != nil {
					metadata.ModificationTime = *takeoutMeta.ModificationTime
				}
				if takeoutMeta.Location != nil {
					metadata.Latitude = takeoutMeta.Location.Latitude
					metadata.Longitude = takeoutMeta.Location.Longitude
				}
				// Note: Description is not in the FileMetadata Zod schema, so we skip it
			}
		}

		// Fallback to file mod time if no metadata
		if metadata == nil || metadata.CreationTime == 0 {
			modTime, _ := uploader.GetFileModTime(fi.Path)
			if metadata == nil {
				metadata = &uploader.SimpleFileMetadata{}
			}
			if metadata.CreationTime == 0 {
				metadata.CreationTime = modTime
			}
			if metadata.ModificationTime == 0 {
				metadata.ModificationTime = modTime
			}
			if metadata.Title == "" {
				metadata.Title = fi.FileName
			}
		}

		// Set FileType (Required by Zod schema)
		// 0 = Image, 1 = Video
		if isVideo(fi.Path) {
			metadata.FileType = 1
		} else {
			metadata.FileType = 0
		}

		// Generate file-specific encryption key
		fileKey, err := uploader.GenerateFileKey()
		if err != nil {
			log.Printf(" ERROR generating file key: %v\n", err)
			errorCount++
			continue
		}

		// Encrypt file key with collection key
		encFileKey, fileKeyNonce, err := uploader.EncryptFileKeyWithCollectionKey(fileKey, collectionKey)
		if err != nil {
			log.Printf(" ERROR encrypting file key: %v\n", err)
			errorCount++
			continue
		}

		// Compute file hash for duplicate detection
		fileHash, err := eCrypto.ComputeFileHash(fi.Path)
		if err != nil {
			debugLog("Warning: failed to compute hash for %s: %v", fi.FileName, err)
		} else {
			metadata.Hash = fileHash
		}

		// Check for duplicates
		dupKey := fmt.Sprintf("%s:%s:%d", metadata.Hash, metadata.Title, metadata.FileType)
		if existingFiles[dupKey] {
			log.Printf(" Skipping duplicate: %s\n", fi.FileName)
			successCount++ // Count as success since it's already there
			continue
		}

		// Encrypt file
		encFile, err := session.ReadAndEncryptFile(fi.Path, fileKey)
		if err != nil {
			log.Printf(" ERROR encrypting file: %v\n", err)
			errorCount++
			continue
		}

		// Log metadata for debugging
		if debugMode {
			mj, _ := json.Marshal(metadata)
			debugLog("Metadata JSON: %s", string(mj))
		}

		// Encrypt metadata
		encMeta, err := session.EncryptMetadata(metadata, fileKey)
		if err != nil {
			log.Printf(" ERROR encrypting metadata: %v\n", err)
			errorCount++
			continue
		}

		// Get upload URLs
		urls, err := ctrl.Client.GetUploadURLs(ctx, 2)
		if err != nil {
			log.Printf(" ERROR getting upload URLs: %v\n", err)
			errorCount++
			continue
		}

		// Generate thumbnail
		encThumb, err := session.GenerateThumbnail(fi.Path, fileKey)
		if err != nil {
			debugLog("Thumbnail generation warning for %s: %v", fi.FileName, err)
		}

		// Upload file to S3
		if err := ctrl.Client.UploadToBucket(ctx, urls[0].URL, encFile.EncryptedData); err != nil {
			log.Printf(" ERROR uploading file: %v\n", err)
			errorCount++
			continue
		}

		// Upload thumbnail if available
		var thumbAttrs *api.UploadedFileAttributes
		if encThumb != nil {
			if err := ctrl.Client.UploadToBucket(ctx, urls[1].URL, encThumb.EncryptedData); err != nil {
				log.Printf(" Warning: failed to upload thumbnail: %v\n", err)
			} else {
				thumbAttrs = &api.UploadedFileAttributes{
					ObjectKey:        urls[1].ObjectKey,
					DecryptionHeader: uploader.EncodeBase64(encThumb.DecryptionHeader),
					Size:             int64(len(encThumb.EncryptedData)),
				}
			}
		}

		// Register file with server
		createReq := &api.CreateFileRequest{
			CollectionID:       collection.ID,
			EncryptedKey:       uploader.EncodeBase64(encFileKey),
			KeyDecryptionNonce: uploader.EncodeBase64(fileKeyNonce),
			File: &api.UploadedFileAttributes{
				ObjectKey:        urls[0].ObjectKey,
				DecryptionHeader: uploader.EncodeBase64(encFile.DecryptionHeader),
				Size:             int64(len(encFile.EncryptedData)),
			},
			Thumbnail: thumbAttrs,
			Metadata: &api.FileAttributes{
				EncryptedData:    uploader.EncodeBase64(encMeta.EncryptedData),
				DecryptionHeader: uploader.EncodeBase64(encMeta.DecryptionHeader),
			},
		}

		fileResp, err := ctrl.Client.CreateFile(ctx, createReq)
		if err != nil {
			log.Printf(" ERROR registering file: %v\n", err)
			errorCount++
			continue
		}

		debugLog("Created file ID: %d", fileResp.ID)
		log.Printf(" ✓ Uploaded successfully\n")
		successCount++

	}

	log.Printf("\n=== Upload Complete ===\n")
	log.Printf("Success: %d files\n", successCount)
	if errorCount > 0 {
		log.Printf("Errors: %d files\n", errorCount)
	}
	log.Printf("Album: %s (ID: %d)\n", albumName, collection.ID)

	return nil
}

// isVideo checks if a file is a video based on extension
func isVideo(path string) bool {
	ext := strings.ToLower(filepath.Ext(path))
	switch ext {
	case ".mp4", ".mov", ".webm", ".mkv", ".avi", ".wmv", ".flv", ".m4v", ".3gp":
		return true
	}
	return false
}

// fetchExistingFilesMap fetches metadata for all files in a collection and builds a map for duplicate detection
func fetchExistingFilesMap(ctx context.Context, client *api.Client, collectionID int64, collectionKey []byte, session *uploader.UploadSession) (map[string]bool, error) {
	filesMap := make(map[string]bool)
	sinceTime := int64(0)
	for {
		files, hasMore, err := client.GetFiles(ctx, collectionID, sinceTime)
		if err != nil {
			return nil, err
		}
		for _, f := range files {
			if f.IsRemovedFromAlbum() {
				continue
			}
			// Decrypt file key
			encFileKey, _ := base64.StdEncoding.DecodeString(f.EncryptedKey)
			nonce, _ := base64.StdEncoding.DecodeString(f.KeyDecryptionNonce)
			fileKey, err := session.DecryptFileKey(encFileKey, nonce, collectionKey)
			if err != nil {
				debugLog("failed to decrypt file key for %d: %v", f.ID, err)
				continue
			}

			// Decrypt metadata
			encMeta, _ := base64.StdEncoding.DecodeString(f.Metadata.EncryptedData)
			metaHeader, _ := base64.StdEncoding.DecodeString(f.Metadata.DecryptionHeader)
			meta, err := session.DecryptMetadata(encMeta, metaHeader, fileKey)
			if err != nil {
				debugLog("failed to decrypt metadata for %d: %v", f.ID, err)
				continue
			}

			if meta.Hash != "" {
				// Key format: hash:title:fileType
				// This matches web client's areFilesSame logic
				key := fmt.Sprintf("%s:%s:%d", meta.Hash, meta.Title, meta.FileType)
				filesMap[key] = true
			}
			if f.UpdationTime > sinceTime {
				sinceTime = f.UpdationTime
			}
		}
		if !hasMore {
			break
		}
	}
	return filesMap, nil
}
