package pkg

import (
	"context"
	"fmt"
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
		fmt.Printf("Syncing account %s\n", account.Email)
		err = c.SyncAccount(account)
		if err != nil {
			fmt.Printf("Error syncing account %s: %s\n", account.Email, err)
			return err
		}
	}
	return nil
}
