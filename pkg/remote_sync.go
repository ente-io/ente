package pkg

import (
	"cli-go/pkg/model"
	"fmt"
	bolt "go.etcd.io/bbolt"
	"log"
)

func (c *ClICtrl) SyncAccount(account model.AccountInfo) error {
	return createDataBuckets(c.DB, account)
}

var dataCategories = []string{"remote-collections", "local-collections", "remote-files", "local-files", "remote-collection-removed", "remote-files-removed"}

func createDataBuckets(db *bolt.DB, account model.AccountInfo) error {
	return db.Update(func(tx *bolt.Tx) error {
		dataBucket, err := tx.CreateBucketIfNotExists([]byte(account.DataBucket()))
		if err != nil {
			return fmt.Errorf("create bucket: %s", err)
		}
		for _, category := range dataCategories {
			exists, err := dataBucket.CreateBucketIfNotExists([]byte(fmt.Sprintf(category)))
			if err != nil {
				return err
			}
			log.Println("SubBucket for category", category, "with parent", account.DataBucket(), "exists:", exists)
		}
		return nil
	})
}
