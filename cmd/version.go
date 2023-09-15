package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

// versionCmd represents the version command
var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Prints the current version",
	Long:  ``,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("ente-cli version %s\n", AppVersion)
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
