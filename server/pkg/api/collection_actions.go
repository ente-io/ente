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

// List returns collection actions for the authenticated user since a timestamp
func (h *CollectionActionsHandler) List(c *gin.Context) {
    userID := auth.GetUserID(c.Request.Header)
    since, _ := strconv.ParseInt(c.Query("sinceTime"), 10, 64)
    limit := 500
    actions, err := h.Controller.Repo.ListForUser(c, userID, since, limit)
    if err != nil {
        handler.Error(c, stacktrace.Propagate(err, ""))
        return
    }
    c.JSON(http.StatusOK, gin.H{
        "actions": actions,
    })
}
