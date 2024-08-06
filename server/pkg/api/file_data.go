package api

import (
	"fmt"
	"github.com/ente-io/museum/ente"
	fileData "github.com/ente-io/museum/ente/filedata"
	"github.com/ente-io/museum/pkg/utils/auth"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"net/http"
	"strconv"
)

func (f *FileHandler) PutFileData(ctx *gin.Context) {
	var req fileData.PutFileDataRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, ente.NewBadRequestWithMessage(err.Error()))
		return
	}
	if err := req.Validate(); err != nil {
		ctx.JSON(http.StatusBadRequest, err)
		return
	}
	reqInt := &req
	if reqInt.Version == nil {
		version := 1
		reqInt.Version = &version
	}
	err := f.FileDataCtrl.InsertOrUpdate(ctx, &req)
	if err != nil {
		handler.Error(ctx, err)

		return
	}
	ctx.JSON(http.StatusOK, gin.H{})
}

func (f *FileHandler) GetFilesData(ctx *gin.Context) {
	var req fileData.GetFilesData
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, ente.NewBadRequestWithMessage(err.Error()))
		return
	}
	resp, err := f.FileDataCtrl.GetFilesData(ctx, req)
	if err != nil {
		handler.Error(ctx, err)
		return
	}
	ctx.JSON(http.StatusOK, resp)
}

func (h *FileHandler) GetVideoUploadURL(c *gin.Context) {
	enteApp := auth.GetApp(c)
	userID, fileID := getUserAndFileIDs(c)
	urls, err := h.Controller.GetVideoUploadUrl(c, userID, fileID, enteApp)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, urls)
}

func (h *FileHandler) GetVideoPreviewUrl(c *gin.Context) {
	userID, fileID := getUserAndFileIDs(c)
	url, err := h.Controller.GetPreviewUrl(c, userID, fileID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"url": url,
	})
}

func (h *FileHandler) ReportVideoPlayList(c *gin.Context) {
	var request ente.InsertOrUpdateEmbeddingRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c,
			stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	err := h.Controller.ReportVideoPreview(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.Status(http.StatusOK)
}

func (h *FileHandler) GetVideoPlaylist(c *gin.Context) {
	fileID, _ := strconv.ParseInt(c.Param("fileID"), 10, 64)
	response, err := h.Controller.GetPlaylist(c, fileID)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, response)
}
