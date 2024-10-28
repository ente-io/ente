package api

import (
	"fmt"
	"github.com/ente-io/museum/ente"
	fileData "github.com/ente-io/museum/ente/filedata"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/ente-io/stacktrace"
	"github.com/gin-gonic/gin"
	"net/http"
)

func (h *FileHandler) PutFileData(ctx *gin.Context) {
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
	err := h.FileDataCtrl.InsertOrUpdate(ctx, &req)
	if err != nil {
		handler.Error(ctx, err)

		return
	}
	ctx.JSON(http.StatusOK, gin.H{})
}

func (h *FileHandler) GetFilesData(ctx *gin.Context) {
	var req fileData.GetFilesData
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, ente.NewBadRequestWithMessage(err.Error()))
		return
	}
	resp, err := h.FileDataCtrl.GetFilesData(ctx, req)
	if err != nil {
		handler.Error(ctx, err)
		return
	}
	ctx.JSON(http.StatusOK, resp)
}

// FileDataStatusDiff API won't really return status/diff for deleted files. The clients will primarily use this data to identify for which all files we already have preview generated or it's ML inference is done.
// This doesn't simulate perfect diff behaviour as we won't maintain a tombstone entries for the deleted API.
func (h *FileHandler) FileDataStatusDiff(ctx *gin.Context) {
	var req fileData.IndexDiffRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, ente.NewBadRequestWithMessage(err.Error()))
		return
	}
	resp, err := h.FileDataCtrl.FileDataStatusDiff(ctx, req)
	if err != nil {
		handler.Error(ctx, err)
		return
	}
	ctx.JSON(http.StatusOK, resp)
}

func (h *FileHandler) GetFileData(ctx *gin.Context) {
	var req fileData.GetFileData
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, ente.NewBadRequestWithMessage(err.Error()))
		return
	}
	resp, err := h.FileDataCtrl.GetFileData(ctx, req)
	if err != nil {
		handler.Error(ctx, err)
		return
	}
	ctx.JSON(http.StatusOK, gin.H{
		"data": resp,
	})
}

func (h *FileHandler) GetPreviewUploadURL(c *gin.Context) {
	var request fileData.PreviewUploadUrlRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	url, err := h.FileDataCtrl.PreviewUploadURL(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"url": url,
	})
}

func (h *FileHandler) GetPreviewURL(c *gin.Context) {
	var request fileData.GetPreviewURLRequest
	if err := c.ShouldBindJSON(&request); err != nil {
		handler.Error(c, stacktrace.Propagate(ente.ErrBadRequest, fmt.Sprintf("Request binding failed %s", err)))
		return
	}
	url, err := h.FileDataCtrl.GetPreviewUrl(c, request)
	if err != nil {
		handler.Error(c, stacktrace.Propagate(err, ""))
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"url": url,
	})
}
