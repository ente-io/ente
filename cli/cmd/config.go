package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// Define the 'config' command and its subcommands
var configCmd = &cobra.Command{
	Use:   "config",
	Short: "Manage configuration settings",
}

// Subcommand for 'config show'
var showCmd = &cobra.Command{
	Use:   "show",
	Short: "Show configuration settings",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("host:", viper.GetString("host"))
	},
}

// Subcommand for 'config update'
var updateCmd = &cobra.Command{
	Use:   "update",
	Short: "Update a configuration setting",
	Run: func(cmd *cobra.Command, args []string) {
		viper.Set("host", host)
		err := viper.WriteConfig()
		if err != nil {
			fmt.Println("Error updating 'host' configuration:", err)
			return
		}
		fmt.Println("Updating 'host' configuration:", host)
	},
}

// Flag to specify the 'host' configuration value
var host string

func init() {
	// Set up Viper configuration
	// Set a default value for 'host' configuration
	viper.SetDefault("host", "https://api.ente.io")

	// Add 'config' subcommands to the root command
	//rootCmd.AddCommand(configCmd)

	// Add flags to the 'config store' and 'config update' subcommands
	updateCmd.Flags().StringVarP(&host, "host", "H", viper.GetString("host"), "Update the 'host' configuration")
	// Mark 'host' flag as required for the 'update' command
	updateCmd.MarkFlagRequired("host")

	// Add 'config' subcommands to the 'config' command
	configCmd.AddCommand(showCmd, updateCmd)
}
