package cmd

import (
	"fmt"
	"log"
	"path/filepath"

	"github.com/ente-io/cli/pkg/takeout"
	"github.com/spf13/cobra"
)

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
}

func runImport(folderPath, albumName string, dryRun, skipMetadata bool) error {
	log.Printf("Scanning Google Takeout folder: %s\n", folderPath)

	// TODO: For now, use a dummy collection ID. In a real implementation,
	// this would come from creating or finding the album
	const dummyCollectionID = 0

	// Scan the folder
	scanResult, err := takeout.ScanFolder(folderPath, dummyCollectionID)
	if err != nil {
		return fmt.Errorf("failed to scan folder: %w", err)
	}

	// Show errors encountered during scan
	if len(scanResult.Errors) > 0 {
		log.Printf("Encountered %d errors during scan:\n", len(scanResult.Errors))
		for i, err := range scanResult.Errors {
			if i < 5 { // Show first 5 errors
				log.Printf("  - %v\n", err)
			}
		}
		if len(scanResult.Errors) > 5 {
			log.Printf("  ... and %d more errors\n", len(scanResult.Errors)-5)
		}
	}

	// Get stats
	stats := scanResult.GetStats(dummyCollectionID)
	log.Printf("\nScan complete:")
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

	// TODO: Actual upload implementation
	log.Println("\nUpload functionality not yet implemented")
	log.Printf("Would upload %d files to album: %s\n", stats.MediaFiles, albumName)

	return nil
}
