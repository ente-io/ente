package emergency

import (
	"fmt"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/controller/lock"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/user"
	"github.com/ente-io/museum/pkg/repo"
	"github.com/ente-io/museum/pkg/repo/emergency"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
)

type Controller struct {
	Repo                  *emergency.Repository
	UserRepo              *repo.UserRepository
	UserCtrl              *user.UserController
	PasskeyController     *controller.PasskeyController
	LockCtrl              *lock.LockController
	isReminderCronRunning bool
}

func (c *Controller) UpdateContact(ctx *gin.Context,
	userID int64,
	req ente.UpdateContact) error {
	if err := validateUpdateReq(userID, req); err != nil {
		return stacktrace.Propagate(err, "")
	}

	// Handle recovery notice update if provided
	if req.RecoveryNoticeInDays != nil {
		// Only the account owner can update recovery notice period
		if req.UserID != userID {
			return stacktrace.Propagate(ente.ErrPermissionDenied, "only account owner can update recovery notice period")
		}
		if *req.RecoveryNoticeInDays < 1 {
			return stacktrace.Propagate(ente.NewBadRequestWithMessage("recovery notice days must be at least 1"), "")
		}
		noticeInHrs := *req.RecoveryNoticeInDays * 24
		hasNoticeUpdate, err := c.Repo.UpdateNoticePeriod(ctx, req.UserID, req.EmergencyContactID, noticeInHrs)
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
		if !hasNoticeUpdate {
			log.WithField("userID", userID).WithField("req", req).
				Warn("No update applied for recovery notice period")
		}
	}

	// Handle state update if provided
	if req.State != "" {
		if req.State == ente.ContactDenied || req.State == ente.ContactLeft || req.State == ente.UserRevokedContact {
			activeSessions, sessionErr := c.Repo.GetActiveSessions(ctx, req.UserID, req.EmergencyContactID)
			if sessionErr != nil {
				return stacktrace.Propagate(sessionErr, "")
			}
			for _, session := range activeSessions {
				if req.State == ente.UserRevokedContact {
					rejErr := c.RejectRecovery(ctx, userID, ente.RecoveryIdentifier{
						ID:                 session.ID,
						UserID:             session.UserID,
						EmergencyContactID: session.EmergencyContactID,
					})
					if rejErr != nil {
						return stacktrace.Propagate(rejErr, "failed to reject recovery")
					}
				} else {
					stopErr := c.StopRecovery(ctx, userID, ente.RecoveryIdentifier{
						ID:                 session.ID,
						UserID:             session.UserID,
						EmergencyContactID: session.EmergencyContactID,
					})
					if stopErr != nil {
						return stacktrace.Propagate(stopErr, "failed to stop recovery")
					}
				}
			}
		}
		hasUpdate, err := c.Repo.UpdateState(ctx, req.UserID, req.EmergencyContactID, req.State)
		if !hasUpdate {
			log.WithField("userID", userID).WithField("req", req).
				Warn("No update applied for emergency contact")
		} else {
			go c.sendContactNotification(ctx, req.UserID, req.EmergencyContactID, req.State)
		}
		if err != nil {
			return stacktrace.Propagate(err, "")
		}
	}

	return nil
}

func (c *Controller) HandleAccountDeletion(ctx *gin.Context, userID int64, logger *log.Entry) error {
	logger.Info("Clean up emergency contacts on account deletion")
	contacts, err := c.Repo.GetActiveContactForUser(ctx, userID)
	if err != nil {
		return stacktrace.Propagate(err, "")
	}
	if len(contacts) == 0 {
		return nil
	}
	for _, contact := range contacts {
		if contact.UserID == userID {
			logger.Info("Removing emergency contact from user side")
			removeErr := c.UpdateContact(ctx, userID, ente.UpdateContact{
				UserID:             userID,
				EmergencyContactID: contact.EmergencyContactID,
				State:              ente.UserRevokedContact,
			})
			if removeErr != nil {
				return stacktrace.Propagate(removeErr, "")
			}
		} else {
			logger.Info("Removing user from emergency contact side")
			leaveErr := c.UpdateContact(ctx, userID, ente.UpdateContact{
				UserID:             contact.UserID,
				EmergencyContactID: userID,
				State:              ente.ContactLeft,
			})
			if leaveErr != nil {
				return stacktrace.Propagate(leaveErr, "")
			}
		}
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

	// If no state is provided, skip state validation (only recovery notice update)
	if req.State == "" {
		return nil
	}

	// Validate state based on who is making the request
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
