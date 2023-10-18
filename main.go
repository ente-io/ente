package main

import (
	"cli-go/cmd"
	"cli-go/internal/api"
	"cli-go/pkg"
	"cli-go/pkg/secrets"
)

func main() {
	db, err := pkg.GetDB("ente-cli.db")
	if err != nil {
		panic(err)
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
