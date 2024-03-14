package cmd

import (
	"context"
	"fmt"
	"github.com/ente-io/cli/pkg/model"
	"github.com/spf13/cobra"
	"github.com/spf13/pflag"
	"strings"
)

var _adminCmd = &cobra.Command{
	Use:   "admin",
	Short: "Commands for admin actions",
	Long:  "Commands for admin actions like disable or enabling 2fa, bumping up the storage limit, etc.",
}

var _userDetailsCmd = &cobra.Command{
	Use:   "get-user-id",
	Short: "Get user id",
	RunE: func(cmd *cobra.Command, args []string) error {
		recoverWithLog()
		var flags = &model.AdminActionForUser{}
		cmd.Flags().VisitAll(func(f *pflag.Flag) {
			if f.Name == "admin-user" {
				flags.AdminEmail = f.Value.String()
			}
			if f.Name == "user" {
				flags.UserEmail = f.Value.String()
			}
		})
		return ctrl.GetUserId(context.Background(), *flags)
	},
}

var _disable2faCmd = &cobra.Command{
	Use:   "disable-2fa",
	Short: "Disable 2fa for a user",
	RunE: func(cmd *cobra.Command, args []string) error {
		recoverWithLog()
		var flags = &model.AdminActionForUser{}
		cmd.Flags().VisitAll(func(f *pflag.Flag) {
			if f.Name == "admin-user" {
				flags.AdminEmail = f.Value.String()
			}
			if f.Name == "user" {
				flags.UserEmail = f.Value.String()
			}
		})
		fmt.Println("Not supported yet")
		return nil
	},
}

var _updateFreeUserStorage = &cobra.Command{
	Use:   "update-subscription",
	Short: "Update subscription for the free user",
	RunE: func(cmd *cobra.Command, args []string) error {
		recoverWithLog()
		var flags = &model.AdminActionForUser{}
		noLimit := false
		cmd.Flags().VisitAll(func(f *pflag.Flag) {
			if f.Name == "admin-user" {
				flags.AdminEmail = f.Value.String()
			}
			if f.Name == "user" {
				flags.UserEmail = f.Value.String()
			}
			if f.Name == "no-limit" {
				noLimit = strings.ToLower(f.Value.String()) == "true"
			}
		})
		return ctrl.UpdateFreeStorage(context.Background(), *flags, noLimit)
	},
}

func init() {
	rootCmd.AddCommand(_adminCmd)
	_ = _userDetailsCmd.MarkFlagRequired("admin-user")
	_ = _userDetailsCmd.MarkFlagRequired("user")
	_userDetailsCmd.Flags().StringP("admin-user", "a", "", "The email of the admin user. (required)")
	_userDetailsCmd.Flags().StringP("user", "u", "", "The email of the user to fetch details for. (required)")
	_disable2faCmd.Flags().StringP("admin-user", "a", "", "The email of the admin user. (required)")
	_disable2faCmd.Flags().StringP("user", "u", "", "The email of the user to disable 2FA for. (required)")
	_updateFreeUserStorage.Flags().StringP("admin-user", "a", "", "The email of the admin user. (required)")
	_updateFreeUserStorage.Flags().StringP("user", "u", "", "The email of the user to update subscription for. (required)")
	// add a flag with no value --no-limit
	_updateFreeUserStorage.Flags().String("no-limit", "True", "When true, sets 100TB as storage limit, and expiry to current date + 100 years")
	_adminCmd.AddCommand(_userDetailsCmd, _disable2faCmd, _updateFreeUserStorage)
}
