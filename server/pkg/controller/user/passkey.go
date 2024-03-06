package user

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// GetTwoFactorRecoveryStatus returns a user's passkey reset status
func (c *UserController) GetTwoFactorRecoveryStatus(ctx *gin.Context) (*ente.TwoFactorRecoveryStatus, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	return c.TwoFactorRecoveryRepo.GetStatus(userID)
}

func (c *UserController) ConfigurePassKeySkip(ctx *gin.Context, req *ente.ConfigurePassKeyRecoveryRequest) error {
	userID := auth.GetUserID(ctx.Request.Header)
	return c.TwoFactorRecoveryRepo.ConfigurePassKeySkipChallenge(ctx, userID, req)
}

func (c *UserController) GetPasskeySkipChallenge(ctx *gin.Context, passKeySessionID string) (*ente.PasseKeySkipChallengeResponse, error) {
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

	result, err := c.TwoFactorRecoveryRepo.GetPasskeySkipChallenge(ctx, userID)
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
	exists, err := c.TwoFactorRecoveryRepo.VerifyPasskeySkipSecret(userID, req.SkipSecret)
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
