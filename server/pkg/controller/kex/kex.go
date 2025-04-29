package kex

import (
	"github.com/ente-io/museum/pkg/repo/kex"
)

type Controller struct {
	Repo *kex.Repository
}

func (c *Controller) AddKey(wrappedKey string, customIdentifier string) (identifier string, err error) {
	return c.Repo.AddKey(wrappedKey, customIdentifier)
}

func (c *Controller) GetKey(identifier string) (wrappedKey string, err error) {
	return c.Repo.GetKey(identifier)
}

func (c *Controller) DeleteOldKeys() {
	c.Repo.DeleteOldKeys()
}
