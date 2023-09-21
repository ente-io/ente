package pkg

import (
	"cli-go/internal/api"
	"cli-go/pkg/model"
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
	app := GetAppType()
	cxt = context.WithValue(cxt, "app", string(app))
	email, flowErr := GetUserInput("Enter email address")
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
		authResponse, keyEncKey, flowErr = c.signInViaPassword(cxt, email, srpAttr)
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
	masterKey, token, decErr := c.decryptMasterKeyAndToken(cxt, authResponse, keyEncKey)
	if decErr != nil {
		flowErr = decErr
		return
	}
	err := c.storeAccount(cxt, email, authResponse.ID, app, masterKey, token)
	if err != nil {
		flowErr = err
		return
	} else {
		fmt.Println("Account added successfully")
	}
}

func (c *ClICtrl) storeAccount(ctx context.Context, email string, userID int64, app api.App, masterKey, token []byte) error {
	// get password
	secret := GetOrCreateClISecret()
	err := c.DB.Update(func(tx *bolt.Tx) error {
		b, err := tx.CreateBucketIfNotExists([]byte(AccBucket))
		if err != nil {
			return err
		}
		accInfo := model.AccountInfo{
			Email:     email,
			UserID:    userID,
			MasterKey: *model.MakeEncString(string(masterKey), secret),
			Token:     *model.MakeEncString(string(token), secret),
			App:       app,
		}
		accInfoBytes, err := json.Marshal(accInfo)
		if err != nil {
			return err
		}
		accountKey := fmt.Sprintf("%s-%d", app, userID)
		return b.Put([]byte(accountKey), accInfoBytes)
	})
	return err
}

func (c *ClICtrl) ListAccounts(cxt context.Context) error {
	err := c.DB.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(AccBucket))
		fmt.Printf("Configured accounts: %d\n", b.Stats().KeyN)
		err := b.ForEach(func(k, v []byte) error {
			var info model.AccountInfo
			err := json.Unmarshal(v, &info)
			if err != nil {
				return err
			}
			fmt.Println("====================================")
			fmt.Println("Email: ", info.Email)
			fmt.Println("UserID: ", info.UserID)
			fmt.Println("App: ", info.App)
			fmt.Println("====================================")
			return nil
		})
		if err != nil {
			return err
		}
		return nil
	})
	if err != nil {
		return err
	}
	return err
}
