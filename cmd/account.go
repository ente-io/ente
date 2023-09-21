package cmd

import (
	"context"

	"github.com/spf13/cobra"
)

// Define the 'account' command and its subcommands
var accountCmd = &cobra.Command{
	Use:   "account",
	Short: "Manage account settings",
}

// Subcommand for 'account list'
var listAccCmd = &cobra.Command{
	Use:   "list",
	Short: "list configured accounts",
	RunE: func(cmd *cobra.Command, args []string) error {
		recoverWithLog()
		return ctrl.ListAccounts(context.Background())
	},
}

// Subcommand for 'account add'
var addAccCmd = &cobra.Command{
	Use:   "add",
	Short: "Add a new account",
	Run: func(cmd *cobra.Command, args []string) {
		recoverWithLog()
		ctrl.AddAccount(context.Background())
	},
}

func init() {
	// Add 'config' subcommands to the root command
	rootCmd.AddCommand(accountCmd)
	// Add 'config' subcommands to the 'config' command
	accountCmd.AddCommand(listAccCmd, addAccCmd)
}
