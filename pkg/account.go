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
	var keyEncKey []byte
	var verifyEmail bool
	var authResponse *api.AuthorizationResponse
	srpAttr, flowErr := c.Client.GetSRPAttributes(cxt, email)
	if flowErr != nil {
		return
	}
	if verifyEmail || srpAttr.IsEmailMFAEnabled {
		flowErr = c.Client.SendEmailOTP(cxt, email)
		if flowErr != nil {
			return
		}
		ott, otpErr := GetCode(
			fmt.Sprintf("Enter OTP sent to email %s (or 'c' to cancel)", email),
			6)
		if otpErr != nil {
			flowErr = otpErr
			return
		}
		authResponse, flowErr = c.Client.VerifyEmail(cxt, email, ott)
	} else {
		authResponse, keyEncKey, flowErr = c.signInViaPassword(cxt, email, srpAttr)
	}
	if flowErr != nil {
		return
	}
	if authResponse.IsMFARequired() {
		authResponse, flowErr = c.validateTOTP(cxt, authResponse)
	}
	if keyEncKey == nil {
		pass, flowErr := GetSensitiveField("Enter password")
		if flowErr != nil {
			return
		} else if pass == "" {
			log.Printf("do work")
		}
	}
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
