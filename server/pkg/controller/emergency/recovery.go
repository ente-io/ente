package emergency

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/repo/emergency"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	log "github.com/sirupsen/logrus"
)

func (c *Controller) GetRecoveryInfo(ctx *gin.Context,
	userID int64,
	sessionID uuid.UUID,
) (*string, *ente.KeyAttributes, error) {
	contact, err := c.validateSessionAndGetContact(ctx, userID, sessionID)
	if err != nil {
		return nil, nil, err
	}
	recoveryTarget, err := c.UserRepo.Get(contact.UserID)
	if err != nil {
		return nil, nil, err
	}
	keyAttr, err := c.UserRepo.GetKeyAttributes(recoveryTarget.ID)
	if err != nil {
		return nil, nil, err
	}
	return contact.EncryptedKey, &keyAttr, nil
}

func (c *Controller) InitChangePassword(ctx *gin.Context, userID int64, request ente.RecoverySrpSetupRequest) (*ente.SetupSRPResponse, error) {
	sessionID := request.RecoveryID
	contact, err := c.validateSessionAndGetContact(ctx, userID, sessionID)
	if err != nil {
		return nil, err
	}
	resp, err := c.UserCtrl.SetupSRP(ctx, contact.UserID, request.SetUpSRPReq)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return resp, nil
}

func (c *Controller) ChangePassword(ctx *gin.Context, userID int64, request ente.RecoveryUpdateSRPAndKeysRequest) (*ente.UpdateSRPSetupResponse, error) {
	sessionID := request.RecoveryID
	contact, err := c.validateSessionAndGetContact(ctx, userID, sessionID)
	if err != nil {
		return nil, err
	}
	resp, err := c.UserCtrl.UpdateSrpAndKeyAttributes(ctx, contact.UserID, request.UpdateSrp, false)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}

	hasUpdate, err := c.Repo.UpdateRecoveryStatusForID(ctx, sessionID, ente.RecoveryStatusRecovered)
	if err != nil {
		return nil, stacktrace.Propagate(err, "failed to update recovery status")
	}
	if !hasUpdate {
		log.WithField("userID", userID).WithField("req", request).
			Warn("no row updated while rejecting recovery")
	}

	return resp, nil
}

func (c *Controller) validateSessionAndGetContact(ctx *gin.Context,
	userID int64,
	sessionID uuid.UUID) (*emergency.ContactRow, error) {
	recoverRow, err := c.Repo.GetRecoverRowByID(ctx, sessionID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if recoverRow.EmergencyContactID != userID {
		return nil, stacktrace.Propagate(ente.ErrPermissionDenied, "only the emergency contact can get recovery info")
	}
	if err = recoverRow.CanRecover(); err != nil {
		return nil, stacktrace.Propagate(ente.NewBadRequestWithMessage(err.Error()), "")
	}
	contact, err := c.Repo.GetActiveEmergencyContact(ctx, recoverRow.UserID, recoverRow.EmergencyContactID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if contact.EncryptedKey == nil {
		return nil, stacktrace.Propagate(ente.ErrNotFound, "no encrypted key found")
	}
	return contact, nil
}
