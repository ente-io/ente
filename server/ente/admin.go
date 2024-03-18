package ente

import (
	"errors"
	"fmt"
)

// GetEmailsFromHashesRequest represents a request to convert hashes
type GetEmailsFromHashesRequest struct {
	Hashes []string `json:"hashes"`
}

// Admin API request to disable 2FA for a user account.
//
// This is used when we get a user request to reset their 2FA when they might've
// lost access to their 2FA codes. We verify their identity out of band.
type DisableTwoFactorRequest struct {
	UserID int64 `json:"userID" binding:"required"`
}

type AdminOpsForUserRequest struct {
	UserID int64 `json:"userID" binding:"required"`
}

// ReQueueItemRequest puts an item back into the queue for processing.
type ReQueueItemRequest struct {
	ID        int64  `json:"id" binding:"required"`
	QueueName string `json:"queueName" binding:"required"`
}

// RecoverAccount is used to recover accounts which are in soft-delete state.
type RecoverAccountRequest struct {
	UserID  int64  `json:"userID" binding:"required"`
	EmailID string `json:"emailID" binding:"required"`
}

// UpdateSubscriptionRequest is used to update a user's subscription
type UpdateSubscriptionRequest struct {
	AdminID         int64                  `json:"-"`
	UserID          int64                  `json:"userID" binding:"required"`
	Storage         int64                  `json:"storage" binding:"required"`
	PaymentProvider PaymentProvider        `json:"paymentProvider"`
	TransactionID   string                 `json:"transactionID" binding:"required"`
	ProductID       string                 `json:"productID" binding:"required"`
	ExpiryTime      int64                  `json:"expiryTime" binding:"required"`
	Attributes      SubscriptionAttributes `json:"attributes"`
}

type ChangeEmailRequest struct {
	UserID int64  `json:"userID" binding:"required"`
	Email  string `json:"email" binding:"required"`
}

type AddOnAction string

const (
	ADD    AddOnAction = "ADD"
	REMOVE AddOnAction = "REMOVE"
	UPDATE AddOnAction = "UPDATE"
)

type UpdateBlackFridayDeal struct {
	Action      AddOnAction `json:"action" binding:"required"`
	UserID      int64       `json:"userID" binding:"required"`
	Year        int         `json:"year"`
	StorageInGB int64       `json:"storageInGB"`
	Testing     bool        `json:"testing"`
	StorageInMB int64       `json:"storageInMB"`
	Minute      int64       `json:"minute"`
}

func (u UpdateBlackFridayDeal) UpdateLog() string {
	if u.Testing {
		return fmt.Sprintf("BF_UPDATE_TESTING: %s, storageInMB: %d, minute: %d", u.Action, u.StorageInMB, u.Minute)
	} else {
		return fmt.Sprintf("BF_UPDATE: %s, storageInGB: %d, year: %d", u.Action, u.StorageInGB, u.Year)
	}
}

func (u UpdateBlackFridayDeal) Validate() error {
	if u.Action == ADD || u.Action == UPDATE {
		if u.Testing {
			if u.StorageInMB == 0 && u.Minute == 0 {
				return errors.New("invalid input, set in MB and minute for test")
			}
		} else {
			if u.StorageInGB != 100 && u.StorageInGB != 2000 && u.StorageInGB != 500 {
				return errors.New("invalid input for deal, only 100, 500, 2000 allowed")
			}
			if u.Year != 3 && u.Year != 5 {
				return errors.New("invalid input for year, only 3 or 5")
			}
		}
	}
	return nil
}

// ClearOrphanObjectsRequest is the API request to trigger the process for
// clearing orphan objects in DC.
//
// The optional prefix can be specified to limit the cleanup to objects that
// begin with that prefix.
//
// ForceTaskLock can be used to force the cleanup to start even if there is an
// existing task lock for the clear orphan objects task.
type ClearOrphanObjectsRequest struct {
	DC            string `json:"dc" binding:"required"`
	Prefix        string `json:"prefix"`
	ForceTaskLock bool   `json:"forceTaskLock"`
}
