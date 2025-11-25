package api

import (
	"net/http"
	"strconv"

	"github.com/ente-io/museum/pkg/controller"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
)

type CollectionActionsHandler struct {
	Controller *controller.CollectionActionsController
}

const pendingRemoveLimit = 2000

// ListPendingRemove returns pending REMOVE actions after the provided updatedAt timestamp
func (h *CollectionActionsHandler) ListPendingRemove(c *gin.Context) {
	userID := auth.GetUserID(c.Request.Header)
	updatedAfter, _ := strconv.ParseInt(c.Query("updatedAt"), 10, 64)
	actions, err := h.Controller.ListPendingRemoveActions(c, userID, updatedAfter, pendingRemoveLimit)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"actions": actions,
	})
}
