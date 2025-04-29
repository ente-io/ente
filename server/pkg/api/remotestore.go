package api

import (
	"fmt"
	"net/http"

	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/controller/remotestore"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// RemoteStoreHandler expose request handlers to all remote store
type RemoteStoreHandler struct {
	Controller *remotestore.Controller
}

// InsertOrUpdate handler for inserting or updating key
func (h *RemoteStoreHandler) InsertOrUpdate(c *gin.Context) {
	var request ente.UpdateKeyValueRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}

	err := h.Controller.InsertOrUpdate(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to update key's value"))
		return
	}
	c.Status(http.StatusOK)
}

// GetKey handler for fetching a value for particular key
func (h *RemoteStoreHandler) GetKey(c *gin.Context) {
	var request ente.GetValueRequest
	if err := c.ShouldBindQuery(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}

	resp, err := h.Controller.Get(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to get key value"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

// GetFeatureFlags returns all the feature flags and value for given user
func (h *RemoteStoreHandler) GetFeatureFlags(c *gin.Context) {
	resp, err := h.Controller.GetFeatureFlags(c)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "failed to get feature flags"))
		return
	}
	c.JSON(http.StatusOK, resp)
}
