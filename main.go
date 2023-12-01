package main

import (
	"fmt"
	"github.com/ente-io/cli/cmd"
	"github.com/ente-io/cli/internal"
	"github.com/ente-io/cli/internal/api"
	"github.com/ente-io/cli/pkg"
	"github.com/ente-io/cli/pkg/secrets"
	"github.com/ente-io/cli/utils/constants"
	"log"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	cliDBPath, err := GetCLIConfigPath()
	if secrets.IsRunningInContainer() {
		cliDBPath = constants.CliDataPath
		_, err := internal.ValidateDirForWrite(cliDBPath)
		if err != nil {
			log.Fatalf("Please mount a volume to %s to persist cli data\n%v\n", cliDBPath, err)
		}
	}

	if err != nil {
		log.Fatalf("Could not create cli config path\n%v\n", err)
	}
	newCliPath := fmt.Sprintf("%s/ente-cli.db", cliDBPath)
	if !strings.HasPrefix(cliDBPath, "/") {
		oldCliPath := fmt.Sprintf("%sente-cli.db", cliDBPath)
		if _, err := os.Stat(oldCliPath); err == nil {
			log.Printf("migrating old cli db from %s to %s\n", oldCliPath, newCliPath)
			if err := os.Rename(oldCliPath, newCliPath); err != nil {
				log.Fatalf("Could not rename old cli db\n%v\n", err)
			}
		}
	}
	db, err := pkg.GetDB(newCliPath)

	if err != nil {
		if strings.Contains(err.Error(), "timeout") {
			log.Fatalf("Please close all other instances of the cli and try again\n%v\n", err)
		} else {
			panic(err)
		}
	}
	ctrl := pkg.ClICtrl{
		Client: api.NewClient(api.Params{
			Debug: false,
			//Host:  "http://localhost:8080",
		}),
		DB:        db,
		KeyHolder: secrets.NewKeyHolder(secrets.GetOrCreateClISecret()),
	}
	err = ctrl.Init()
	if err != nil {
		panic(err)
	}
	defer func() {
		if err := db.Close(); err != nil {
			panic(err)
		}
	}()
	cmd.Execute(&ctrl)
}

// GetCLIConfigPath returns the path to the .ente-cli folder and creates it if it doesn't exist.
func GetCLIConfigPath() (string, error) {
	if os.Getenv("ENTE_CLI_CONFIG_PATH") != "" {
		return os.Getenv("ENTE_CLI_CONFIG_PATH"), nil
	}
	// Get the user's home directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}

	cliDBPath := filepath.Join(homeDir, ".ente")

	// Check if the folder already exists, if not, create it
	if _, err := os.Stat(cliDBPath); os.IsNotExist(err) {
		err := os.MkdirAll(cliDBPath, 0755)
		if err != nil {
			return "", err
		}
	}

	return cliDBPath, nil
}
