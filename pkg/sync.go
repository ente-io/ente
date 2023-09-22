package pkg

import "context"

func (c *ClICtrl) StartSync() error {
	accounts, err := c.GetAccounts(context.Background())
	if err != nil {
		return err
	}
	for _, account := range accounts {
		err = c.SyncAccount(account)
		if err != nil {
			return err
		}
	}
	return nil
}
