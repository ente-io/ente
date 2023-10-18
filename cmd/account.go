package cmd

import (
	"cli-go/internal/api"
	"cli-go/pkg/model"
	"context"
	"fmt"
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

// Subcommand for 'account update'
var updateAccCmd = &cobra.Command{
	Use:   "update",
	Short: "Update an existing account's export directory",
	Run: func(cmd *cobra.Command, args []string) {
		recoverWithLog()
		exportDir, _ := cmd.Flags().GetString("dir")
		app, _ := cmd.Flags().GetString("app")
		email, _ := cmd.Flags().GetString("email")
		if email == "" {
			fmt.Println("email must be specified")
			return
		}
		if exportDir == "" {
			fmt.Println("dir param must be specified")
			return
		}

		validApps := map[string]bool{
			"photos": true,
			"locker": true,
			"auth":   true,
		}

		if !validApps[app] {
			fmt.Printf("invalid app. Accepted values are 'photos', 'locker', 'auth'")

		}
		err := ctrl.UpdateAccount(context.Background(), model.UpdateAccountParams{
			Email:     email,
			App:       api.StringToApp(app),
			ExportDir: &exportDir,
		})
		if err != nil {
			fmt.Printf("Error updating account: %v\n", err)
		}
	},
}

func init() {
	// Add 'config' subcommands to the root command
	rootCmd.AddCommand(accountCmd)
	// Add 'config' subcommands to the 'config' command
	updateAccCmd.Flags().String("dir", "", "update export directory")
	updateAccCmd.Flags().String("email", "", "email address of the account to update")
	updateAccCmd.Flags().String("app", "photos", "Specify the app, default is 'photos'")
	accountCmd.AddCommand(listAccCmd, addAccCmd, updateAccCmd)
}
