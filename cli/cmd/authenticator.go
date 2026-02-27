package cmd

import (
	"context"

	"github.com/ente-io/cli/pkg/authenticator"
	"github.com/spf13/cobra"
)

// Define the 'config' command and its subcommands
var authenticatorCmd = &cobra.Command{
	Use:   "auth",
	Short: "Authenticator commands",
}

// Subcommand for 'auth decrypt'
var decryptExportCmd = &cobra.Command{
	Use:   "decrypt [input] [output]",
	Short: "Decrypt authenticator export",
	Args:  cobra.ExactArgs(2), // Ensures exactly two arguments are passed
	RunE: func(cmd *cobra.Command, args []string) error {
		inputPath := args[0]
		outputPath := args[1]

		password, _ := cmd.Flags().GetString("password")

		return authenticator.DecryptExport(inputPath, outputPath, password)
	},
}

// Subcommand for 'auth list'
var listCodesCmd = &cobra.Command{
	Use:   "list",
	Short: "List current TOTP codes for all authenticator entries",
	RunE: func(cmd *cobra.Command, args []string) error {
		issuer, _ := cmd.Flags().GetString("issuer")
		return ctrl.ListCodes(context.Background(), issuer)
	},
}

func init() {
	decryptExportCmd.Flags().StringP("password", "p", "", "Password for decryption")
	listCodesCmd.Flags().StringP("issuer", "i", "", "Filter by issuer name (case-insensitive substring match)")

	rootCmd.AddCommand(authenticatorCmd)
	authenticatorCmd.AddCommand(decryptExportCmd)
	authenticatorCmd.AddCommand(listCodesCmd)
}
