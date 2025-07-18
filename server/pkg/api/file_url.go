package api

import (
	"github.com/ente-io/museum/ente"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"net/http"
	"strconv"
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

func (h *FileHandler) LinkInfo(c *gin.Context) {

}

func (h *FileHandler) LinkThumbnail(c *gin.Context) {
	linkCtx := auth.MustGetFileLinkAccessContext(c)
	url, err := h.Controller.GetThumbnailURL(c, linkCtx.OwnerID, linkCtx.FileID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Redirect(http.StatusTemporaryRedirect, url)
}

func (h *FileHandler) LinkFile(c *gin.Context) {
	linkCtx := auth.MustGetFileLinkAccessContext(c)
	url, err := h.Controller.GetFileURL(c, linkCtx.OwnerID, linkCtx.FileID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Redirect(http.StatusTemporaryRedirect, url)
}

func (h *FileHandler) DisableUrl(c *gin.Context) {
	cID, err := strconv.ParseInt(c.Param("fileID"), 10, 64)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, ""))
		return
	}
	err = h.FileUrlCtrl.Disable(c, cID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{})
}

func (h *FileHandler) GetUrls(c *gin.Context) {
	sinceTime, err := strconv.ParseInt(c.Query("sinceTime"), 10, 64)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, ""))
		return
	}
	limit := 500
	if c.Query("limit") != "" {
		limit, err = strconv.Atoi(c.Query("limit"))
		if err != nil || limit < 1 {
			handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, ""))
			return
		}
	}
	response, err := h.FileUrlCtrl.GetUrls(c, sinceTime, int64(limit))
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"diff": response,
	})
}

// UpdateFileURL updates the share URL for a file
func (h *FileHandler) UpdateFileURL(c *gin.Context) {
	var req ente.UpdateFileUrl
	if err := c.ShouldBindJSON(&req); err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	response, err := h.FileUrlCtrl.UpdateSharedUrl(c, req)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"result": response,
	})
}
