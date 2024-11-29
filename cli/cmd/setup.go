package cmd 

import (
  "fmt"
  "os"
  "net/url"
  "strings"
  
  "github.com/spf13/viper"
  "github.com/spf13/cobra"

  "github.com/ente-io/cli/pkg"
)

var setupCmd = &cobra.Command {
  Use: "setup",
  Short: "Manage setup/configuration settings",
}

// Command to set the public albums url in configurations/<environment>.yaml file
// Reads value from environment variable "ENTE_MUSEUM_DIR"
var addPublicAlbumsUrl = &cobra.Command {
  Use: "public-albums-url account add-public-url [url]",
  Short: "Set the public-albums URL in Museum YAML configuraiton file",
  Args: cobra.ExactArgs(1),
  Run: func(cmd *cobra.Command, args []string) {
    // Get environment to make changes to valid file  
    environment := os.Getenv("ENVIRONMENT")

    if environment == "" {
      environment = "local"
    } 

    dir := pkg.ConfigureServerDir()

    // Adding path to the museum config file
    viper.AddConfigPath(dir)
    viper.SetConfigName(environment)
    viper.SetConfigType("yaml")

    err := viper.ReadInConfig()
    if err != nil {
      fmt.Errorf("%v", err)
      return
    }
    albumsUrl := strings.TrimSuffix(args[0], "/")
    _, err = url.ParseRequestURI(albumsUrl)
    if err != nil {
      // Report Error and exit
      fmt.Printf("Invalid URL: %s\nPlease enter a valid endpoint for public albums", err) 
      os.Exit(1)
    } else {
      viper.Set("apps.public-albums", albumsUrl)
    }

    // Overwrite the public album url in Configuration File
    err = viper.WriteConfig()
    if err != nil {
      fmt.Println("Error saving config: %v\n", err)
    } else {
      fmt.Println("Public Albums URL set to", albumsUrl)
    }
  },
}

func init() {
  // `ente setup` will be the initial root command
  rootCmd.AddCommand(setupCmd)
  rootCmd.Flags().String("public-albums-url", "", "Sets the public-albums url in your environments configuration file")

  setupCmd.AddCommand(addPublicAlbumsUrl)
}
