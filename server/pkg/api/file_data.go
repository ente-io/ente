package api

import (
	"github.com/ente-io/museum/ente"
	fileData "github.com/ente-io/museum/ente/filedata"
	"github.com/ente-io/museum/pkg/utils/handler"
	"github.com/gin-gonic/gin"
	"net/http"
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
