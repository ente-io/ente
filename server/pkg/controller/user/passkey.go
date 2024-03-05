package user

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/gin-gonic/gin"
)

// GetAccountRecoveryStatus returns a user's passkey reset status
func (c *UserController) GetAccountRecoveryStatus(ctx *gin.Context) (*ente.AccountRecoveryStatus, error) {
	userID := auth.GetUserID(ctx.Request.Header)
	return c.AccountRecoveryRepo.GetAccountRecoveryStatus(userID)
}
