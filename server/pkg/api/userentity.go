package api

import (
	"fmt"
	"net/http"

	"github.com/ente-io/museum/ente"
	model "github.com/ente-io/museum/ente/userentity"
	userentity "github.com/ente-io/museum/pkg/controller/userentity"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

// UserEntityHandler expose request handlers for various operations on user entity
type UserEntityHandler struct {
	Controller *userentity.Controller
}

// CreateKey...
func (h *UserEntityHandler) CreateKey(c *gin.Context) {
	var request model.EntityKeyRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	if err := request.Type.IsValid(); err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Invalid EntityType"))
		return
	}
	err := h.Controller.CreateKey(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to create CreateKey"))
		return
	}
	c.Status(http.StatusOK)
}

// GetKey...
func (h *UserEntityHandler) GetKey(c *gin.Context) {
	var request model.GetEntityKeyRequest
	if err := c.ShouldBindQuery(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	resp, err := h.Controller.GetKey(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to Get EntityKey"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

// CreateEntity...
func (h *UserEntityHandler) CreateEntity(c *gin.Context) {
	var request model.EntityDataRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	resp, err := h.Controller.CreateEntity(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to create CreateEntityKey"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

// UpdateEntity...
func (h *UserEntityHandler) UpdateEntity(c *gin.Context) {
	var request model.UpdateEntityDataRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	resp, err := h.Controller.UpdateEntity(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to update EntityKey"))
		return
	}
	c.JSON(http.StatusOK, resp)
}

// DeleteEntity...
func (h *UserEntityHandler) DeleteEntity(c *gin.Context) {
	id := c.Query("id")
	_, err := h.Controller.Delete(c, id)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to delete EntityKey"))
		return
	}
	c.Status(http.StatusOK)
}

// GetDiff...
func (h *UserEntityHandler) GetDiff(c *gin.Context) {
	var request model.GetEntityDiffRequest
	if err := c.ShouldBindQuery(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}

	entities, err := h.Controller.GetDiff(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, "Failed to fetch  entityData diff"))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"diff": entities,
	})
}
