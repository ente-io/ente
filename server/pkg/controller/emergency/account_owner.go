package emergency

import (
	"database/sql"
	"errors"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/time"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

func (c *Controller) AddContact(ctx *gin.Context, userID int64, request ente.AddContact) error {
	emergencyContactID, err := c.UserRepo.GetUserIDWithEmail(request.Email)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return stacktrace.Propagate(ente.ErrNotFound, "invited member is not on ente")
		} else {
			return stacktrace.Propagate(err, "")
		}
	}
	noticeInHrs := 24 * 30
	if request.RecoveryNoticeInDays != nil {
		noticeInHrs = *request.RecoveryNoticeInDays * 24
	}
	hasUpdated, err := c.Repo.AddEmergencyContact(ctx, userID, emergencyContactID, request.EncryptedKey, noticeInHrs)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if hasUpdated {
		go c.sendContactNotification(ctx, userID, emergencyContactID, ente.UserInvitedContact)
	}
	return nil
}

func (c *Controller) GetInfo(ctx *gin.Context, userID int64) (*ente.EmergencyDataResponse, error) {
	contacts, err := c.Repo.GetActiveContactForUser(ctx, userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	userIDs := make([]int64, 0, len(contacts))
	for _, contact := range contacts {
		userIDs = append(userIDs, contact.EmergencyContactID)
		userIDs = append(userIDs, contact.UserID)
	}
	recoverRows, err := c.Repo.GetActiveRecoverySessions(ctx, userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	for _, session := range recoverRows {
		userIDs = append(userIDs, session.UserID)
		userIDs = append(userIDs, session.EmergencyContactID)
	}
	userIdToUserMap, err := c.UserRepo.GetActiveUsersForIds(userIDs)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	userEmergencyContacts := make([]*ente.EmergencyContactEntity, 0)
	othersEmergencyContact := make([]*ente.EmergencyContactEntity, 0)
	for _, contact := range contacts {
		user, ok1 := userIdToUserMap[contact.UserID]
		emergencyContactUser, ok2 := userIdToUserMap[contact.EmergencyContactID]
		if !ok1 || !ok2 {
			continue
		}
		entity := &ente.EmergencyContactEntity{
			User: ente.BasicUser{
				ID:    user.ID,
				Email: user.Email,
			},
			EmergencyContact: ente.BasicUser{
				ID:    emergencyContactUser.ID,
				Email: emergencyContactUser.Email,
			},
			State:                contact.State,
			RecoveryNoticeInDays: contact.NoticePeriodInHrs / 24,
		}
		if contact.UserID == userID {
			userEmergencyContacts = append(userEmergencyContacts, entity)
		} else {
			othersEmergencyContact = append(othersEmergencyContact, entity)
		}
	}
	recoverSessions := make([]*ente.RecoverySession, 0)
	othersRecoverSessions := make([]*ente.RecoverySession, 0)
	nowInMicroseconds := time.Microseconds()
	for _, session := range recoverRows {
		user, ok1 := userIdToUserMap[session.UserID]
		emergencyContactUser, ok2 := userIdToUserMap[session.EmergencyContactID]
		if !ok1 || !ok2 {
			continue
		}
		waitTime := session.WaitTill - nowInMicroseconds
		status := session.Status
		if waitTime < 0 {
			if status == ente.RecoveryStatusWaiting {
				status = ente.RecoveryStatusReady
			}
			waitTime = 0
		}

		entity := &ente.RecoverySession{
			ID: session.ID,
			User: ente.BasicUser{
				ID:    user.ID,
				Email: user.Email,
			},
			EmergencyContact: ente.BasicUser{
				ID:    emergencyContactUser.ID,
				Email: emergencyContactUser.Email,
			},
			Status:    status,
			WaitTill:  waitTime,
			CreatedAt: session.CreatedAt,
		}
		if session.UserID == userID {
			recoverSessions = append(recoverSessions, entity)
		} else {
			othersRecoverSessions = append(othersRecoverSessions, entity)
		}
	}

	response := &ente.EmergencyDataResponse{
		Contacts:               userEmergencyContacts,
		OthersEmergencyContact: othersEmergencyContact,
		RecoverySessions:       recoverSessions,
		OthersRecoverSessions:  othersRecoverSessions,
	}
	return response, nil
}
