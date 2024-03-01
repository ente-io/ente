package api

import (
	"net/http"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// PushHandler exposes request handlers for all push related requests
type PushHandler struct {
	PushController *controller.PushController
}

func (h *PushHandler) AddToken(c *gin.Context) {
	var req ente.PushTokenRequest
	err := c.ShouldBindJSON(&req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	err = h.PushController.AddToken(auth.GetUserID(c.Request.Header), req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{})
}
