package pkg

import (
	"cli-go/internal/api"
	bolt "go.etcd.io/bbolt"
)

type ClICtrl struct {
	Client *api.Client
	DB     *bolt.DB
}
