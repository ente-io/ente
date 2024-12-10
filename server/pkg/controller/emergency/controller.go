package emergency

import (
	"fmt"
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/user"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/repo/emergency"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

type Controller struct {
	Repo     *emergency.Repository
	UserRepo *repo.UserRepository
	UserCtrl *user.UserController
}

func (c *Controller) UpdateContact(ctx *gin.Context,
	userID int64,
	req ente.UpdateContact) error {
	if err := validateUpdateReq(userID, req); err != nil {
		return stacktrace.Propagate(err, "")
	}
	hasUpdate, err := c.Repo.UpdateState(ctx, req.UserID, req.EmergencyContactID, req.State)
	if !hasUpdate {
		log.WithField("userID", userID).WithField("req", req).
			Warn("No update applied for emergency contact")
	}
	recoverStatus := getNextRecoveryStatusFromContactState(req.State)
	if recoverStatus != nil {
		if err := c.Repo.UpdateRecoveryStatus(ctx, req.UserID, req.EmergencyContactID, *recoverStatus); err != nil {
			return stacktrace.Propagate(err, "")
		}
	}
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	return nil
}

func validateUpdateReq(userID int64, req ente.UpdateContact) error {
	if req.EmergencyContactID == req.UserID {
		return stacktrace.Propagate(ente.NewBadRequestWithMessage("contact and user can not be same"), "")
	}
	if req.EmergencyContactID != userID && req.UserID != userID {
		return stacktrace.Propagate(ente.ErrPermissionDenied, "user can only update his own state")
	}

	isActorContact := userID == req.EmergencyContactID
	if isActorContact {
		if req.State == ente.ContactAccepted ||
			req.State == ente.ContactLeft ||
			req.State == ente.ContactDenied {
			return nil
		}
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("Can not update state to %s", req.State)), "")
	} else {
		if req.State == ente.UserInvitedContact ||
			req.State == ente.UserRevokedContact {
			return nil
		}
		return stacktrace.Propagate(ente.NewBadRequestWithMessage(fmt.Sprintf("Can not update state to %s", req.State)), "")
	}
}

// When a user contact state is update, we need to update the recovery status for any ongoing recovery
func getNextRecoveryStatusFromContactState(state ente.ContactState) *ente.RecoveryStatus {
	switch state {
	case ente.ContactAccepted:
		return nil
	case ente.UserInvitedContact:
		return nil
	case ente.ContactLeft:
		return ente.RecoveryStatusStopped.Ptr()
	case ente.ContactDenied:
		return ente.RecoveryStatusStopped.Ptr()
	case ente.UserRevokedContact:
		return ente.RecoveryStatusRejected.Ptr()
	}
	return nil
}
