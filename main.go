/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
*/
package main

import (
	"cli-go/cmd"
	"cli-go/internal/api"
	"cli-go/pkg"
	"fmt"
	bolt "go.etcd.io/bbolt"
	"log"
)

var db *bolt.DB
var client = api.NewClient(api.Params{
	Debug: true,
})

func main() {
	db, err := pkg.GetDB("ente-cli.db")
	if err != nil {
		panic(err)
	}
	db.Update(func(tx *bolt.Tx) error {
		log.Println("creating #AccBucket")
		_, err := tx.CreateBucketIfNotExists([]byte(pkg.AccBucket))
		if err != nil {
			return fmt.Errorf("create bucket: %s", err)
		}
		return nil
	})
	ctrl := pkg.ClICtrl{
		Client: client,
		DB:     db,
	}
	defer func() {
		log.Println("closing db")
		if err := db.Close(); err != nil {
			panic(err)
		}
	}()
	cmd.Execute(&ctrl)
}
