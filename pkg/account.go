package pkg

import (
	"context"
	"encoding/json"
	bolt "go.etcd.io/bbolt"
)

const AccBucket = "accounts"

type AccountInfo struct {
	Email  string `json:"email" binding:"required"`
	UserID int64  `json:"userID" binding:"required"`
}

func (c *ClICtrl) AddAccount(cxt context.Context, email string, userID int64) error {
	return c.DB.Update(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(AccBucket))
		info := AccountInfo{
			Email:  email,
			UserID: userID,
		}
		value, err := json.Marshal(info)
		if err != nil {
			return err
		}
		err = b.Put([]byte(email), value)
		return err
	})
}
