package api

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"net/http"
)

// ShareUrl a sharable url for the file
func (h *FileHandler) ShareUrl(c *gin.Context) {
	var file ente.CreateFileUrl
	if err := c.ShouldBindJSON(&file); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}

	response, err := h.FileUrlCtrl.CreateLink(c, file)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, response)
}
