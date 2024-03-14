package pkg

import (
	"context"
	"fmt"
	"github.com/ente-io/cli/internal"
	"github.com/ente-io/cli/pkg/model"
	"github.com/ente-io/cli/utils"
	"log"
	"strings"
	"time"
)

func (c *ClICtrl) GetUserId(ctx context.Context, params model.AdminActionForUser) error {
	accountCtx, err := c.buildAdminContext(ctx, params.AdminEmail)
	if err != nil {
		return err
	}
	id, err := c.Client.GetUserIdFromEmail(accountCtx, params.UserEmail)
	if err != nil {
		return err
	}
	fmt.Println(id.User.ID)
	return nil
}

func (c *ClICtrl) UpdateFreeStorage(ctx context.Context, params model.AdminActionForUser, noLimit bool) error {
	accountCtx, err := c.buildAdminContext(ctx, params.AdminEmail)
	if err != nil {
		return err
	}
	userDetails, err := c.Client.GetUserIdFromEmail(accountCtx, params.UserEmail)
	if err != nil {
		return err
	}
	if noLimit {
		// set storage to 100TB and expiry to + 100 years
		err := c.Client.UpdateFreePlanSub(accountCtx, userDetails, 100*1024*1024*1024*1024, time.Now().AddDate(100, 0, 0).UnixMicro())
		if err != nil {
			return err
		} else {
			fmt.Println("Successfully updated storage and expiry date for user")
		}
		return nil
	}
	storageSize, err := internal.GetStorageSize("Enter a storage size (e.g.'5MB', '10GB', '2Tb'): ")
	if err != nil {
		log.Fatalf("Error: %v", err)
	}
	dateStr, err := internal.GetUserInput("Enter sub expiry date in YYYY-MM-DD format  (e.g.'2040-12-31')")
	if err != nil {
		log.Fatalf("Error: %v", err)
	}
	date, err := _parseDateOrDateTime(dateStr)
	if err != nil {
		return err
	}

	fmt.Printf("Updating storage for user %s to %s (old %s) with new expirty %s (old %s) \n",
		params.UserEmail,
		utils.ByteCountDecimalGIB(storageSize), utils.ByteCountDecimalGIB(userDetails.Subscription.Storage),
		date.Format("2006-01-02"),
		time.UnixMicro(userDetails.Subscription.ExpiryTime).Format("2006-01-02"))
	// press y to confirm
	confirmed, _ := internal.ConfirmAction("Are you sure you want to update the storage ('y' or 'n')?")
	if !confirmed {
		return nil
	} else {
		err := c.Client.UpdateFreePlanSub(accountCtx, userDetails, storageSize, date.UnixMicro())
		if err != nil {
			return err
		} else {
			fmt.Println("Successfully updated storage and expiry date for user")
		}
	}

	return nil
}

func (c *ClICtrl) buildAdminContext(ctx context.Context, adminEmail string) (context.Context, error) {
	accounts, err := c.GetAccounts(ctx)
	if err != nil {
		return nil, err
	}
	var acc *model.Account
	for _, a := range accounts {
		if a.Email == adminEmail {
			acc = &a
			break
		}
	}
	if acc == nil {
		return nil, fmt.Errorf("account not found for %s, use `account list` to list accounts", adminEmail)
	}
	secretInfo, err := c.KeyHolder.LoadSecrets(*acc)
	if err != nil {
		return nil, err
	}
	accountCtx := c.buildRequestContext(ctx, *acc)
	c.Client.AddToken(acc.AccountKey(), secretInfo.TokenStr())
	return accountCtx, nil
}

func _parseDateOrDateTime(input string) (time.Time, error) {
	var layout string
	if strings.Contains(input, " ") {
		// If the input contains a space, assume it's a date-time format
		layout = "2006-01-02 15:04:05"
	} else {
		// If there's no space, assume it's just a date
		layout = "2006-01-02"
	}
	return time.Parse(layout, input)
}
