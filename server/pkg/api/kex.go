package api

import (
	"errors"
	"net/http"

	"github.com/ente-io/museum/ente"
	kexCtrl "github.com/ente-io/museum/pkg/controller/kex"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

type KexHandler struct {
	Controller *kexCtrl.Controller
}

func (h *KexHandler) AddKey(c *gin.Context) {
	req := ente.AddWrappedKeyRequest{}
	if err := c.ShouldBindJSON(&req); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}

	identifier, err := h.Controller.AddKey(req.WrappedKey, req.CustomIdentifier)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"identifier": identifier,
	})
}

func (h *KexHandler) GetKey(c *gin.Context) {
	identifier := c.Query("identifier")

	if identifier == "" {
		handler.Error(c, stacktrace.Propagate(errors.New("identifier is required"), ""))
		return
	}

	wrappedKey, err := h.Controller.GetKey(identifier)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"wrappedKey": wrappedKey,
	})
}
