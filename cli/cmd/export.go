package cmd

import (
	"github.com/ente-io/cli/pkg/model/export"
	"github.com/spf13/cobra"
)

// exportCmd represents the export command
var exportCmd = &cobra.Command{
	Use:   "export",
	Short: "Starts the export process",
	Long:  ``,
	Run: func(cmd *cobra.Command, args []string) {
		// Retrieve flag values
		shared, _ := cmd.Flags().GetBool("shared")
		sharedFiles, _ := cmd.Flags().GetBool("shared-files")
		hidden, _ := cmd.Flags().GetBool("hidden")
		albums, _ := cmd.Flags().GetStringSlice("albums")
		emails, _ := cmd.Flags().GetStringSlice("emails")

		// Create Filters struct with flag values
		filters := export.Filters{
			ExcludeShared:      !shared,
			ExcludeSharedFiles: !sharedFiles,
			ExcludeHidden:      !hidden,
			Albums:             albums,
			Emails:             emails,
		}

		// Call the Export function with the filters
		ctrl.Export(filters)
	},
}

func init() {
	rootCmd.AddCommand(exportCmd)

	// Add flags for Filters struct fields with default value true
	exportCmd.Flags().Bool("shared", true, "Include shared albums in export")
	exportCmd.Flags().Bool("shared-files", true, "Include shared files in export")
	exportCmd.Flags().Bool("hidden", true, "Include hidden albums in export")
	exportCmd.Flags().StringSlice("albums", []string{}, "Comma-separated list of album names to export")
	exportCmd.Flags().StringSlice("emails", []string{}, "Comma-separated list of emails to export files shared with")
}
