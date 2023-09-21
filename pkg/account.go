package pkg

import (
	"cli-go/internal/api"
	"context"
	"encoding/json"
	"fmt"
	"log"

	bolt "go.etcd.io/bbolt"
)

const AccBucket = "accounts"

type AccountInfo struct {
	Email  string  `json:"email" binding:"required"`
	UserID int64   `json:"userID" binding:"required"`
	App    api.App `json:"app" binding:"required"`
}

func (c *ClICtrl) AddAccount(cxt context.Context) {
	var flowErr error
	defer func() {
		if r := recover(); r != nil {
			log.Println("recovered from panic", r)
		}
		if flowErr != nil {
			log.Fatal(flowErr)
		}
	}()

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
		log.Fatal("no encrypted token or keyAttributes")
		return
	}
	masterKey, token, decErr := c.decryptMasterKeyAndToken(cxt, authResponse, keyEncKey)
	if decErr != nil {
		flowErr = decErr
		return
	}
	// print length
	fmt.Printf("master key length: %d\n", len(masterKey))
	fmt.Printf("token length: %d\n", len(token))
}

func (c *ClICtrl) ListAccounts(cxt context.Context) error {
	err := c.DB.View(func(tx *bolt.Tx) error {
		b := tx.Bucket([]byte(AccBucket))
		log.Printf("total accounts: %d", b.Stats().KeyN)
		err := b.ForEach(func(k, v []byte) error {
			var info AccountInfo
			err := json.Unmarshal(v, &info)
			if err != nil {
				return err
			}
			log.Println(info)
			return nil
		})
		if err != nil {
			log.Fatal("error listing accounts", err)
			return err
		}
		return nil
	})
	if err != nil {
		log.Fatal("error listing accounts", err)
		return err
	}
	return err

}
