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
	"strings"
)

func main() {
	cliDBPath := ""
	if secrets.IsRunningInContainer() {
		cliDBPath = constants.CliDataPath
		_, err := internal.ValidateDirForWrite(cliDBPath)
		if err != nil {
			log.Fatalf("Please mount a volume to %s to persist cli data\n%v\n", cliDBPath, err)
		}
	}
	db, err := pkg.GetDB(fmt.Sprintf("%sente-cli.db", cliDBPath))
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
