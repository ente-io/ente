package pkg

import (
	"context"
	"fmt"
	"log"
)

func (c *ClICtrl) StartSync() error {
	accounts, err := c.GetAccounts(context.Background())
	if err != nil {
		return err
	}
	if len(accounts) == 0 {
		fmt.Printf("No accounts to sync\n")
		return nil
	}
	for _, account := range accounts {
		log.SetPrefix(fmt.Sprintf("[%s-%s] ", account.App, account.Email))
		log.Println("start sync")
		err = c.SyncAccount(account)
		if err != nil {
			fmt.Printf("Error syncing account %s: %s\n", account.Email, err)
			return err
		} else {
			log.Println("sync done")
		}

	}
	return nil
}
