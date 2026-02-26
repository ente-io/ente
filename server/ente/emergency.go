package ente

import "github.com/google/uuid"

type AddContact struct {
	Email        string `json:"email" binding:"required"`
	EncryptedKey string `json:"encryptedKey" binding:"required"`
	// Indicates after how many days, the emergency contact will be able to recover the account, if the user
	// does not deny the recovery request
	RecoveryNoticeInDays *int `json:"recoveryNoticeInDays"`
}

type UpdateContact struct {
	UserID             int64        `json:"userID" binding:"required"`
	EmergencyContactID int64        `json:"emergencyContactID" binding:"required"`
	State              ContactState `json:"state" binding:"required"`
}

type UpdateRecoveryNotice struct {
	EmergencyContactID   int64 `json:"emergencyContactID" binding:"required"`
	RecoveryNoticeInDays int   `json:"recoveryNoticeInDays" binding:"required"`
}

type ContactIdentifier struct {
	UserID             int64 `json:"userID" binding:"required"`
	EmergencyContactID int64 `json:"emergencyContactID" binding:"required"`
}

type RecoveryIdentifier struct {
	ID                 uuid.UUID `json:"id" binding:"required"`
	UserID             int64     `json:"userID" binding:"required"`
	EmergencyContactID int64     `json:"emergencyContactID" binding:"required"`
}

type ContactState string

const (
	UserInvitedContact ContactState = "INVITED"
	UserRevokedContact ContactState = "REVOKED"
	ContactAccepted    ContactState = "ACCEPTED"
	ContactLeft        ContactState = "CONTACT_LEFT"
	ContactDenied      ContactState = "CONTACT_DENIED"
)

type EmergencyContactEntity struct {
	User                 BasicUser    `json:"user"`
	EmergencyContact     BasicUser    `json:"emergencyContact"`
	State                ContactState `json:"state"`
	RecoveryNoticeInDays int32        `json:"recoveryNoticeInDays"`
}

type RecoveryStatus string

const (
	RecoveryStatusInitiated RecoveryStatus = "INITIATED"
	RecoveryStatusWaiting   RecoveryStatus = "WAITING"
	RecoveryStatusRejected  RecoveryStatus = "REJECTED"
	RecoveryStatusRecovered RecoveryStatus = "RECOVERED"
	RecoveryStatusStopped   RecoveryStatus = "STOPPED"
	RecoveryStatusReady     RecoveryStatus = "READY"
)

func (rs RecoveryStatus) Ptr() *RecoveryStatus {
	return &rs
}

type RecoverySession struct {
	ID               uuid.UUID      `json:"id"`
	User             BasicUser      `json:"user"`
	EmergencyContact BasicUser      `json:"emergencyContact"`
	Status           RecoveryStatus `json:"status"`
	WaitTill         int64          `json:"waitTill"`
	CreatedAt        int64          `json:"createdAt"`
}

type EmergencyDataResponse struct {
	Contacts               []*EmergencyContactEntity `json:"contacts"`
	RecoverySessions       []*RecoverySession        `json:"recoverSessions"`
	OthersEmergencyContact []*EmergencyContactEntity `json:"othersEmergencyContact"`
	OthersRecoverSessions  []*RecoverySession        `json:"othersRecoverySession"`
}
