package pkg

import (
	"cli-go/internal"
	"cli-go/internal/api"
	"cli-go/pkg/model"
	"cli-go/utils/encoding"
	"context"
	"encoding/json"
	"fmt"
	"log"

	bolt "go.etcd.io/bbolt"
)

const AccBucket = "accounts"

func (c *ClICtrl) AddAccount(cxt context.Context) {
	var flowErr error
	defer func() {
		if flowErr != nil {
			log.Fatal(flowErr)
		}
	}()
	app := internal.GetAppType()
	cxt = context.WithValue(cxt, "app", string(app))
	email, flowErr := internal.GetUserInput("Enter email address")
	if flowErr != nil {
		return
	}
	var verifyEmail bool

	srpAttr, flowErr := c.Client.GetSRPAttributes(cxt, email)
	if flowErr != nil {
		// if flowErr type is ApiError and status code is 404, then set verifyEmail to true and continue
		// else return
		if apiErr, ok := flowErr.(*api.ApiError); ok && apiErr.StatusCode == 404 {
			verifyEmail = true
		} else {
			return
		}
	}
	var authResponse *api.AuthorizationResponse
	var keyEncKey []byte
	if verifyEmail || srpAttr.IsEmailMFAEnabled {
		authResponse, flowErr = c.validateEmail(cxt, email)
	} else {
		authResponse, keyEncKey, flowErr = c.signInViaPassword(cxt, srpAttr)
	}
	if flowErr != nil {
		return
	}
	if authResponse.IsMFARequired() {
		authResponse, flowErr = c.validateTOTP(cxt, authResponse)
	}
	if authResponse.EncryptedToken == "" || authResponse.KeyAttributes == nil {
		panic("no encrypted token or keyAttributes")
	}
	secretInfo, decErr := c.decryptAccSecretInfo(cxt, authResponse, keyEncKey)
	if decErr != nil {
		flowErr = decErr
		return
	}
	err := c.storeAccount(cxt, email, authResponse.ID, app, secretInfo)
	if err != nil {
		flowErr = err
		return
	} else {
		fmt.Println("Account added successfully")
	}
}

func (c *ClICtrl) storeAccount(_ context.Context, email string, userID int64, app api.App, secretInfo *model.AccSecretInfo) error {
	// get password
	err := c.DB.Update(func(tx *bolt.Tx) error {
		b, err := tx.CreateBucketIfNotExists([]byte(AccBucket))
		if err != nil {
			return err
		}
		accInfo := model.Account{
			Email:     email,
			UserID:    userID,
			MasterKey: *model.MakeEncString(secretInfo.MasterKey, c.KeyHolder.DeviceKey),
			SecretKey: *model.MakeEncString(secretInfo.SecretKey, c.KeyHolder.DeviceKey),
			Token:     *model.MakeEncString(secretInfo.Token, c.KeyHolder.DeviceKey),
			App:       app,
			PublicKey: encoding.EncodeBase64(secretInfo.PublicKey),
		}
		accInfoBytes, err := json.Marshal(accInfo)
		if err != nil {
			return err
		}
		accountKey := accInfo.AccountKey()
		return b.Put([]byte(accountKey), accInfoBytes)
	})
	return err
}

func (c *ClICtrl) GetAccounts(cxt context.Context) ([]model.Account, error) {
	var accounts []model.Account
	err := c.DB.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(AccBucket))
		err := b.ForEach(func(k, v []byte) error {
			var info model.Account
			err := json.Unmarshal(v, &info)
			if err != nil {
				return err
			}
			accounts = append(accounts, info)
			return nil
		})
		if err != nil {
			return err
		}
		return nil
	})
	return accounts, err
}

func (c *ClICtrl) ListAccounts(cxt context.Context) error {
	accounts, err := c.GetAccounts(cxt)
	if err != nil {
		return err
	}
	fmt.Printf("Configured accounts: %d\n", len(accounts))
	for _, acc := range accounts {
		fmt.Println("====================================")
		fmt.Println("Email: ", acc.Email)
		fmt.Println("ID:    ", acc.UserID)
		fmt.Println("App:   ", acc.App)
		fmt.Println("====================================")
	}
	return nil
}
