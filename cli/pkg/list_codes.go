package pkg

import (
	"context"
	"encoding/base64"
	"fmt"
	"os"
	"strings"
	"text/tabwriter"

	"github.com/ente-io/cli/internal/api"
	"github.com/ente-io/cli/pkg/authenticator"
	"github.com/ente-io/cli/pkg/model"
)

// ListCodes fetches TOTP entries from all configured auth accounts and prints
// the current code for each. An optional issuerFilter restricts output to
// entries whose issuer contains the filter string (case-insensitive).
func (c *ClICtrl) ListCodes(ctx context.Context, issuerFilter string) error {
	accounts, err := c.GetAccounts(ctx)
	if err != nil {
		return err
	}

	found := false
	for _, account := range accounts {
		// Filter BoltDB accounts for auth-app accounts
		if account.App != api.AppAuth {
			continue
		}
		found = true

		secretInfo, err := c.KeyHolder.LoadSecrets(account)
		if err != nil {
			return err
		}

		// Inject "app", "account_key", "user_id", "model.FilterKey" into Context
		ctx = c.buildRequestContext(ctx, account, model.Filter{})
		err = createDataBuckets(c.DB, account) // no-op if buckets already exist
		if err != nil {
			return err
		}
		c.Client.AddToken(account.AccountKey(), base64.URLEncoding.EncodeToString(secretInfo.Token))

		// Get the URIs from Context
		uris, err := c.fetchRemoteAuthenticatorData(ctx)
		if err != nil {
			return fmt.Errorf("error fetching authenticator data for %s: %v", account.Email, err)
		}

		// Call GenerateTOTPCode in totp.go, filter, and print nicely
		fmt.Printf("Account: %s\n", account.Email)
		w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
		for _, uri := range uris {
			code, err := authenticator.GenerateTOTPCode(uri)
			if err != nil {
				fmt.Fprintf(w, "  [error: %v]\n", err)
				continue
			}
			if issuerFilter != "" && !strings.Contains(strings.ToLower(code.Issuer), strings.ToLower(issuerFilter)) {
				continue
			}
			fmt.Fprintf(w, "  %s\t%s\t%s\t%ds\n", code.Issuer, code.Account, code.Code, code.ExpiresIn)
		}
		w.Flush()
	}

	if !found {
		fmt.Println("No auth accounts configured. Add one with: ente account add --app auth")
	}
	return nil
}
