package cmd

import (
	"github.com/spf13/cobra"
)

// versionCmd represents the version command
var exportCmd = &cobra.Command{
	Use:   "export",
	Short: "Starts the export process",
	Long:  ``,
	Run: func(cmd *cobra.Command, args []string) {
		ctrl.StartSync()
	},
}

func init() {
	rootCmd.AddCommand(exportCmd)
}
