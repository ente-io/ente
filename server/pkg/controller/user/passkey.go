package user

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// GetAccountRecoveryStatus returns a user's passkey reset status
func (c *UserController) GetAccountRecoveryStatus(ctx *gin.Context) (*ente.TwoFactorRecoveryStatus, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	return c.TwoFactorRecoveryRepo.GetStatus(userID)
}

func (c *UserController) ConfigurePassKeySkip(ctx *gin.Context, req *ente.ConfigurePassKeySkipRequest) error {
	userID := auth.GetUserID(ctx.Request.Header)
	return c.TwoFactorRecoveryRepo.ConfigurePassKeyRecovery(ctx, userID, req)
}

func (c *UserController) GetPasskeySkipChallenge(ctx *gin.Context, passKeySessionID string) (*ente.EncData, error) {
	userID, err := c.PasskeyRepo.GetUserIDWithPasskeyTwoFactorSession(passKeySessionID)
	if err != nil {
		return nil, err
	}
	recoveryStatus, err := c.TwoFactorRecoveryRepo.GetStatus(userID)
	if err != nil {
		return nil, err
	}
	if !recoveryStatus.IsPassKeySkipEnabled {
		return nil, ente.NewBadRequestWithMessage("Passkey reset is not configured")
	}

	result, err := c.TwoFactorRecoveryRepo.GetPasskeyResetChallenge(ctx, userID)
	if err != nil {
		return nil, err
	}
	if result == nil {
		return nil, ente.NewBadRequestWithMessage("Passkey reset is not configured")
	}
	return result, nil
}

func (c *UserController) SkipPassKey(context *gin.Context, req *ente.SkipPassKeyRequest) (*ente.TwoFactorAuthorizationResponse, error) {
	userID, err := c.PasskeyRepo.GetUserIDWithPasskeyTwoFactorSession(req.SessionID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	exists, err := c.TwoFactorRecoveryRepo.VerifyRecoveryKeyForPassKey(userID, req.PassKeySkipSecret)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	if !exists {
		return nil, stacktrace.Propagate(ente.ErrPermissionDenied, "")
	}
	response, err := c.GetKeyAttributeAndToken(context, userID)
	if err != nil {
		return nil, stacktrace.Propagate(err, "")
	}
	return &response, nil
}
